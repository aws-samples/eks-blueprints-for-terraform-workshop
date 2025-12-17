import * as cdk from "aws-cdk-lib";
import * as iam from "aws-cdk-lib/aws-iam";
import { aws_s3 as s3 } from "aws-cdk-lib";
import * as eks from "aws-cdk-lib/aws-eks";
import * as ssm from "aws-cdk-lib/aws-ssm";
import { Construct } from "constructs";
import { VSCodeIde } from "@workshop-cdk-constructs/vscode-ide";
import {
  CdkSynthMode,
  WorkshopStudioTeamStack,
} from "@workshop-cdk-constructs/workshop-studio-utils";
import { CodeBuildCustomResource } from "@workshop-cdk-constructs/codebuild-custom-resource";
import * as codebuild from "aws-cdk-lib/aws-codebuild";

import * as fs from "fs";
import * as path from "path";
import { EksCall } from "aws-cdk-lib/aws-stepfunctions-tasks";

let bootstrap = fs.readFileSync(
  path.join(__dirname, "../resources/bootstrap.sh"),
  { encoding: "utf-8" },
);
const buildspecCommon = fs.readFileSync(
  path.join(__dirname, "../resources/buildspec-common.yaml"),
  {
    encoding: "utf-8",
  },
);

const buildspecHub = fs.readFileSync(
  path.join(__dirname, "../resources/buildspec-hub.yaml"),
  {
    encoding: "utf-8",
  },
);

const buildspecSpoke = fs.readFileSync(
  path.join(__dirname, "../resources/buildspec-spoke.yaml"),
  {
    encoding: "utf-8",
  },
);

export class TeamStack extends WorkshopStudioTeamStack {
  constructor(scope: Construct, id: string) {
    super(scope, id);

    //let ParticipantAssumedRoleArn = this.getParticipantAssumedRoleArn();

    const { bucketPrefix, deployedBucket } = this.getAssetsBucket("../assets");

    const tfStateBackendBucket = new s3.Bucket(this, "TFStateBackendBucket", {
      versioned: true,
      removalPolicy: cdk.RemovalPolicy.RETAIN,
      autoDeleteObjects: false,
    });

    const sharedRole = new iam.Role(this, "SharedRole", {
      assumedBy: new iam.CompositePrincipal(
        new iam.ServicePrincipal("ec2.amazonaws.com"),
        new iam.ServicePrincipal("codebuild.amazonaws.com"),
        new iam.ServicePrincipal("glue.amazonaws.com"),
      ),

      managedPolicies: [
        // Replace this with IAM permissions your user will need for cluster creation/IDE
        iam.ManagedPolicy.fromAwsManagedPolicyName("AdministratorAccess"),
      ],
    });

    const bootstrapScript = cdk.Fn.sub(bootstrap, {
      BUCKET_NAME: tfStateBackendBucket.bucketName,
      AssetsBucketName: deployedBucket?.bucketName || "",
      AssetsBucketPrefix: bucketPrefix,
      WORKSHOP_GIT_URL:
        process.env.WORKSHOP_GIT_URL ||
        "https://github.com/aws-samples/eks-blueprints-for-terraform-workshop",
      WORKSHOP_GIT_BRANCH: process.env.WORKSHOP_GIT_BRANCH || "vscode",
    });

    const ide = new VSCodeIde(this, "IDE-BLUE", {
      bootstrapScript: bootstrapScript,
      role: sharedRole,
      terminalOnStartup: false,
      bootstrapTimeoutMinutes: 30,
      enableGitea: true,
      codeServerVersion: "4.100.1",
    });

    // if (this.getCdkSynthMode() !== CdkSynthMode.SynthWorkshopStudio) {
    //   ParticipantAssumedRoleArn = new cdk.CfnParameter(
    //     this,
    //     "ParticipantAssumedRoleArn",
    //     { type: "String" },
    //   ).valueAsString;
    // }

    const commonRunner = new CodeBuildCustomResource(this, "EKSWSCOMMON", {
      buildspec: buildspecCommon,
      codeBuildTimeout: cdk.Duration.minutes(60),
      computeType: codebuild.ComputeType.SMALL,
      environmentVariables: {
        TFSTATE_BUCKET_NAME: { value: tfStateBackendBucket.bucketName },
        WORKSHOP_GIT_URL: {
          value:
            process.env.WORKSHOP_GIT_URL ||
            "https://github.com/aws-samples/eks-blueprints-for-terraform-workshop",
        },
        WORKSHOP_GIT_BRANCH: {
          value: process.env.WORKSHOP_GIT_BRANCH || "vscode",
        },
        FORCE_DELETE_VPC: { value: process.env.FORCE_DELETE_VPC || "false" },
        GITEA_PASSWORD: { value: ide.getIdePassword() },
        IS_WS: {
          value:
            this.getCdkSynthMode() == CdkSynthMode.SynthWorkshopStudio
              ? "true"
              : "false",
        },
      },
      buildImage: codebuild.LinuxBuildImage.AMAZON_LINUX_2_4,
      role: sharedRole,
      //removalPolicy: cdk.RemovalPolicy.RETAIN,
    });

    // making common depend on ide, so the ide is the last thing to get deleted
    commonRunner.customResource.node.addDependency(ide.bootstrapped);
    // making ide dependent on commonRunner to ensure that git repos are setup by the time ide is ready
    //cannot do it cause circular dependency ide.node.addDependency(commonRunner.customResource); // Since we are using cluster alias in the bootstrap

    //Calling the SSM document to make sure all repo where pushed
    const ssmDocument = new ssm.CfnDocument(this, "SetupGit", {
      documentType: "Command",
      documentFormat: "YAML",
      updateMethod: "NewVersion",
      targetType: "/AWS::EC2::Instance",
      content: {
        schemaVersion: "2.2",
        description: "Setup Git",
        parameters: {},      
        mainSteps: [
          {
            action: "aws:runShellScript",
            name: "WaitForDirectoryAndSetupGit",
            inputs: {
              runCommand: [
                "#!/bin/bash",
                "MAX_ATTEMPTS=60",
                "WAIT_SECONDS=120",
                "DIRECTORY='/home/ec2-user/eks-blueprints-for-terraform-workshop'",
                "",
                "for ((i=1; i<=MAX_ATTEMPTS; i++)); do",
                '  if [ -d "$DIRECTORY" ]; then',
                '    echo "Directory $DIRECTORY exists. Proceeding with Git setup."',
                "    sudo su - ec2-user -c \"ls -la '$DIRECTORY'\"",
                '    if [ -f "$DIRECTORY/setup-git.sh" ]; then',
                '      echo "Found setup-git.sh. Executing..."',
                '      echo "DEBUG: About to execute setup-git.sh"',
                '      echo "DEBUG: Current directory: $(pwd)"',
                '      echo "DEBUG: Current user: $(whoami)"',
                "      sudo su - ec2-user -c \"GITOPS_DIR=/home/ec2-user/environment/gitops-repos '$DIRECTORY/setup-git.sh'\" > /tmp/setup-git.log 2>&1",
                "      SETUP_GIT_EXIT_CODE=$?",
                '      echo "DEBUG: setup-git.sh completed with exit code: $SETUP_GIT_EXIT_CODE"',
                '      echo "DEBUG: Last 20 lines of setup-git.sh output:"',
                "      tail -20 /tmp/setup-git.log",
                "      if [ $SETUP_GIT_EXIT_CODE -ne 0 ]; then",
                '        echo "ERROR: setup-git.sh failed"',
                "        cat /tmp/setup-git.log",
                "        exit $SETUP_GIT_EXIT_CODE",
                "      fi",
                '      echo "DEBUG: Checking for setup-template.sh..."',
                '      ls -la "$DIRECTORY/setup-template.sh"',
                '      if [ -f "$DIRECTORY/setup-template.sh" ]; then',
                '        echo "DEBUG: Found setup-template.sh. File details:"',
                '        ls -la "$DIRECTORY/setup-template.sh"',
                '        echo "DEBUG: File permissions and ownership look good"',
                '        echo "Found setup-template.sh. Executing..."',
                '        echo "DEBUG: About to run setup-template.sh with env vars"',
                "        sudo su - ec2-user -c \"PROJECT_CONTEXT_PREFIX=eks-blueprints-workshop AWS_REGION=us-west-2 '$DIRECTORY/setup-template.sh'\" > /tmp/setup-template.log 2>&1",
                "        SETUP_TEMPLATE_EXIT_CODE=$?",
                '        echo "DEBUG: setup-template.sh completed with exit code: $SETUP_TEMPLATE_EXIT_CODE"',
                '        echo "DEBUG: Last 20 lines of setup-template.sh output:"',
                "        tail -20 /tmp/setup-template.log",
                "        if [ $SETUP_TEMPLATE_EXIT_CODE -ne 0 ]; then",
                '          echo "ERROR: setup-template.sh failed"',
                "          cat /tmp/setup-template.log",
                "          exit $SETUP_TEMPLATE_EXIT_CODE",
                "        fi",
                "      else",
                '        echo "DEBUG: setup-template.sh NOT found"',
                '        echo "DEBUG: Directory contents:"',
                '        ls -la "$DIRECTORY/"',
                '        echo "Warning: setup-template.sh not found in $DIRECTORY"',
                "      fi",
                '      echo "DEBUG: Final log file sizes:"',
                "      ls -la /tmp/setup-*.log",
                '      echo "DEBUG: Both scripts completed successfully"',
                "      exit 0",
                "    else",
                '      echo "Error: setup-git.sh not found in $DIRECTORY"',
                '      ls -la "$DIRECTORY"',
                "      exit 1",
                "    fi",
                "  else",
                '    echo "Attempt $i: Directory $DIRECTORY does not exist yet. Waiting..."',
                "    sleep $WAIT_SECONDS",
                "  fi",
                "done",
                "",
                'echo "Directory $DIRECTORY did not appear after $MAX_ATTEMPTS attempts. Exiting."',
                "exit 1",
              ],
            },
          },
        ],
      },
    });

    const hubRunner = new CodeBuildCustomResource(this, "EKSWSHUB", {
      buildspec: buildspecHub,
      codeBuildTimeout: cdk.Duration.minutes(60),
      computeType: codebuild.ComputeType.SMALL,
      environmentVariables: {
        TFSTATE_BUCKET_NAME: { value: tfStateBackendBucket.bucketName },
        WORKSHOP_GIT_URL: {
          value:
            process.env.WORKSHOP_GIT_URL ||
            "https://github.com/aws-samples/eks-blueprints-for-terraform-workshop",
        },
        WORKSHOP_GIT_BRANCH: {
          value: process.env.WORKSHOP_GIT_BRANCH || "vscode",
        },
        FORCE_DELETE_VPC: { value: process.env.FORCE_DELETE_VPC || "false" },
        GITEA_PASSWORD: { value: ide.getIdePassword() },
        IS_WS: {
          value:
            this.getCdkSynthMode() == CdkSynthMode.SynthWorkshopStudio
              ? "true"
              : "false",
        },
      },
      buildImage: codebuild.LinuxBuildImage.AMAZON_LINUX_2_4,
      role: sharedRole,
      //removalPolicy: cdk.RemovalPolicy.RETAIN,
    });
    hubRunner.customResource.node.addDependency(commonRunner.customResource);

    const spokeDevRunner = new CodeBuildCustomResource(this, "EKSWSSPOKEDEV", {
      buildspec: buildspecSpoke,
      codeBuildTimeout: cdk.Duration.minutes(60),
      computeType: codebuild.ComputeType.SMALL,
      environmentVariables: {
        TFSTATE_BUCKET_NAME: { value: tfStateBackendBucket.bucketName },
        WORKSPACE: { value: "dev" },
        WORKSHOP_GIT_URL: {
          value:
            process.env.WORKSHOP_GIT_URL ||
            "https://github.com/aws-samples/eks-blueprints-for-terraform-workshop",
        },
        WORKSHOP_GIT_BRANCH: {
          value: process.env.WORKSHOP_GIT_BRANCH || "vscode",
        },
        FORCE_DELETE_VPC: { value: process.env.FORCE_DELETE_VPC || "false" },
        GITEA_PASSWORD: { value: ide.getIdePassword() },
        IS_WS: {
          value:
            this.getCdkSynthMode() == CdkSynthMode.SynthWorkshopStudio
              ? "true"
              : "false",
        },
      },
      buildImage: codebuild.LinuxBuildImage.AMAZON_LINUX_2_4,
      role: sharedRole,
      //removalPolicy: cdk.RemovalPolicy.RETAIN,
    });
    spokeDevRunner.customResource.node.addDependency(
      commonRunner.customResource,
    );

    const spokeProdRunner = new CodeBuildCustomResource(
      this,
      "EKSWSSPOKEPROD",
      {
        buildspec: buildspecSpoke,
        codeBuildTimeout: cdk.Duration.minutes(60),
        computeType: codebuild.ComputeType.SMALL,
        environmentVariables: {
          TFSTATE_BUCKET_NAME: { value: tfStateBackendBucket.bucketName },
          WORKSPACE: { value: "prod" },
          WORKSHOP_GIT_URL: {
            value:
              process.env.WORKSHOP_GIT_URL ||
              "https://github.com/aws-samples/eks-blueprints-for-terraform-workshop",
          },
          WORKSHOP_GIT_BRANCH: {
            value: process.env.WORKSHOP_GIT_BRANCH || "vscode",
          },
          FORCE_DELETE_VPC: { value: process.env.FORCE_DELETE_VPC || "false" },
          GITEA_PASSWORD: { value: ide.getIdePassword() },
          IS_WS: {
            value:
              this.getCdkSynthMode() == CdkSynthMode.SynthWorkshopStudio
                ? "true"
                : "false",
          },
        },
        buildImage: codebuild.LinuxBuildImage.AMAZON_LINUX_2_4,
        role: sharedRole,
        //removalPolicy: cdk.RemovalPolicy.RETAIN,
      },
    );
    spokeProdRunner.customResource.node.addDependency(
      commonRunner.customResource,
    );

    ssmDocument.node.addDependency(commonRunner.customResource);
    ssmDocument.node.addDependency(hubRunner.customResource);
    ssmDocument.node.addDependency(spokeDevRunner.customResource);
    ssmDocument.node.addDependency(spokeProdRunner.customResource);

    new cdk.CfnOutput(this, "IdeUrl", { value: ide.accessUrl });
    new cdk.CfnOutput(this, "IdePassword", { value: ide.getIdePassword() });
  }
}

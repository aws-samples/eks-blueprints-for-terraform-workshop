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
                "      sudo su - ec2-user -c \"GITOPS_DIR=/home/ec2-user/environment/gitops-repos '$DIRECTORY/setup-git.sh'\"",
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

    ssmDocument.node.addDependency(commonRunner.customResource);
    const association = new cdk.aws_ssm.CfnAssociation(
      this,
      "SetupGitAssociation",
      {
        associationName: "SetupGitAssociation",
        name: ssmDocument.ref,
        targets: [
          {
            key: "tag:aws:cloudformation:stack-name",
            values: [this.stackName, "eks-blueprints-workshop-team-stack"],
          },
        ],
      },
    );

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

    const spokeRunner = new CodeBuildCustomResource(this, "EKSWSSPOKE", {
      buildspec: buildspecSpoke,
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
    spokeRunner.customResource.node.addDependency(commonRunner.customResource);

    new cdk.CfnOutput(this, "IdeUrl", { value: ide.accessUrl });
    new cdk.CfnOutput(this, "IdePassword", { value: ide.getIdePassword() });
  }
}

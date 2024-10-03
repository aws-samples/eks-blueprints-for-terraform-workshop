import { Construct } from "constructs";

import { WorkshopStudioCentralStack } from "@workshop-cdk-constructs/workshop-studio-utils";

export class CentralAccountStack extends WorkshopStudioCentralStack {
  constructor(scope: Construct, id: string) {
    super(scope, id);

    const { bucketPrefix, deployedBucket } = this.getAssetsBucket("../assets");

    // Add resources for central account if required
  }
}

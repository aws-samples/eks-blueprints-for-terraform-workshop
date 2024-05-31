
#used preview_build for local development: 
#https://studio.us-east-1.prod.workshops.aws/preview/580d5100-7d5d-4475-a08a-869479cdb428/builds/57a6cd8c-95a2-4fae-b2e7-03ee4935e9f4/en-US/authoring-a-workshop/local-development

# Download preview_build from here https://catalog.workshops.aws/docs/en-US/create-a-workshop/authoring-a-workshop/local-development

preview:
	preview_build

assets-upload: build
	aws s3 sync ./assets s3://ws-assets-us-east-1/d2b662ae-e9d7-4b31-b68b-64ade19d5dcc

assets-list:
	aws s3 ls s3://ws-assets-us-east-1/d2b662ae-e9d7-4b31-b68b-64ade19d5dcc

build:
	cd static/scripts && ./workshop_assets.sh

repolinter:
	rm code/eks-blueprint/eks-blue/terraform.tfvars
	rm code/eks-blueprint/environment/terraform.tfvars
	node ~/bin/repolinter/bin/repolinter.js /home/ec2-user/environment/eks/blog/eks-blueprints-for-terraform-workshop -r ~/bin/amazon-ospo-ruleset.json | tee -a /tmp/repolinter.log
	git restore code/eks-blueprint/environment/terraform.tfvars
	git restore code/eks-blueprint/eks-blue/terraform.tfvars
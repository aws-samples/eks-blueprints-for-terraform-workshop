#!/bin/bash
#Check assets are up to date for self-paced deployment
if [[ ! -f ../../assets/cfn.yml ]]; then
  cp ../../static/cfn.yml ../../assets/cfn.yml
fi
if [[ $(sdiff -s ../../static/cfn.yml ../../assets/cfn.yml) ]]; then
  echo "You should update static/cfn.yml from assets/cfn.yml"
  exit
else
  echo "Cfn Assets are up to date. static/cfn.yml -> assets/cfn.yml"
fi
echo "======Clearing out folders and creating directory structure======"
cd ..
rm -rf tmp
mkdir tmp
cd tmp
mkdir code-eks-blueprint
cd code-eks-blueprint
echo "======Adding Additional code======"
ls -la ../../../code/eks-blueprint/
cp -r ../../../code/eks-blueprint/* . 
echo "======Deleting unrequired folders======"
#rm -rf node_modules
#rm -rf package-lock.json
echo "======Creating zip archive======"
zip -ry ../code-eks-blueprint.zip *
cd ..
echo "======Move to assets folder======"
mv *.zip ../../assets/
echo "======Cleaning up======"
cd ..
rm -r tmp # delete this line to test the app, navigate to static/tmp/workshop and run nmp i and then npm start.
# Important - you need to retrigger a build once the new assets have been synced
echo "======Complete======"
echo "======Remember to trigger a build once the assts are synced======"

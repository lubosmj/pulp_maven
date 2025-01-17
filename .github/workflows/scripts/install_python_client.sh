#!/bin/bash

# WARNING: DO NOT EDIT!
#
# This file was generated by plugin_template, and is managed by it. Please use
# './plugin-template --github pulp_maven' to update this file.
#
# For more info visit https://github.com/pulp/plugin_template

set -euv

export PULP_URL="${PULP_URL:-http://pulp}"

# make sure this script runs at the repo root
cd "$(dirname "$(realpath -e "$0")")"/../../..

pip install twine wheel

export REPORTED_VERSION=$(http pulp/pulp/api/v3/status/ | jq --arg plugin maven --arg legacy_plugin pulp_maven -r '.versions[] | select(.component == $plugin or .component == $legacy_plugin) | .version')
export DESCRIPTION="$(git describe --all --exact-match `git rev-parse HEAD`)"
if [[ $DESCRIPTION == 'tags/'$REPORTED_VERSION ]]; then
  export VERSION=${REPORTED_VERSION}
else
  export EPOCH="$(date +%s)"
  export VERSION=${REPORTED_VERSION}${EPOCH}
fi

export response=$(curl --write-out %{http_code} --silent --output /dev/null https://pypi.org/project/pulp-maven-client/$VERSION/)

if [ "$response" == "200" ];
then
  echo "pulp_maven client $VERSION has already been released. Installing from PyPI."
  pip install pulp-maven-client==$VERSION
  mkdir -p dist
  tar cvf python-client.tar ./dist
  exit
fi

cd ../pulp-openapi-generator

./generate.sh pulp_maven python $VERSION
cd pulp_maven-client
python setup.py sdist bdist_wheel --python-tag py3
pip install dist/pulp_maven_client-$VERSION-py3-none-any.whl
tar cvf ../../pulp_maven/python-client.tar ./dist
exit $?

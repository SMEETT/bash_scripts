#!/bin/bash
# VARS
: ${strapi_project_name:="strapi_test_script"}
: ${strapi_url:="https://cms.borisfries.dev"}
: ${strapi_target_dir:="/var/lib/pm2node/$strapi_project_name"}
: ${strapi_repo_name:="$strapi_project_name"}
: ${strapi_add_gh_repo:=true}

set -e

yes | npx create-strapi-app@latest $strapi_project_name --quickstart --no-run
cd $strapi_project_name

# move delevelopment config to its own folder
mkdir -p ./config/development
mv ./config/server.js ./config/development/

# add production config
cat > ./config/server.cjs <<EOF
module.exports = ({ env }) => ({
  host: env("HOST", "0.0.0.0"),
  port: env.int("PORT", 1337),
  url: "$strapi_url",
  app: {
    keys: env.array("APP_KEYS"),
  },
});
EOF

# later be run by PM2 Process Manager
cat > ./strapi_server.js <<EOF
const strapi = require("@strapi/strapi");
strapi(/* {...} */).start();
EOF


# add PM2 ecosystem config
cat > ./ecosystem.config.cjs <<EOF
module.exports = {
  apps: [
    {
      name: "$strapi_project_name",
      script: "./strapi_server.js",
      watch: false,
      ignore_watch: ["database"],
      autorestart: true,
      env: {
        NODE_ENV: "production",
        ENV_PATH: "$strapi_target_dir/.env.production",
      },
    },
  ],
};
EOF

#add deploy script
cat > ./deploy_script.sh <<EOF
pm2 kill
cd $strapi_target_dir
yes | npx dotenv-vault login
npx dotenv-vault pull production
npm install
npm run build
pm2 start ecosystem.config.js
pm2 save
EOF

# add github action yml
mkdir -p ./.github/workflows/
cat > ./.github/workflows/deploy.yml <<EOF
name: Deploy
on: [push]

jobs:
  build:
    # 'if' will only run gh-action if '[deploy]' is part of the commit-message
    if: "contains(github.event.head_commit.message, '[deploy]')"
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v1
      # scp repository to specified directory on VPS starting at root of repo (".")
      - name: Copy repository contents via scp
        uses: appleboy/scp-action@master
        env:
          HOST: \${{ secrets.HOST }}
          USERNAME: \${{ secrets.USERNAME }}
          PORT: \${{ secrets.PORT }}
          KEY: \${{ secrets.SSHKEY }}
        with:
          source: "."
          target: "$strapi_target_dir"

      # "appleboy/ssh-action@master" will run commands directly on the target machine (namely our VPS)
      - name: Build and Run
        uses: appleboy/ssh-action@master
        with:
          host: \${{ secrets.HOST }}
          USERNAME: \${{ secrets.USERNAME }}
          PORT: \${{ secrets.PORT }}
          KEY: \${{ secrets.SSHKEY }}
          script: sh $strapi_target_dir/deploy_script.sh
EOF

if [ "$strapi_add_gh_repo" = true ] ; then
git init
git add .
git commit -m "first commit"
git branch -M main
gh repo create $strapi_repo_name --private
git remote add origin git@github.com:SMEETT/$strapi_repo_name.git
git push -u origin main
fi

npx dotenv-vault new
exec bash

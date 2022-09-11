#!/bin/bash
# VARS
: ${strapi_project_name:="my_strapi_project"}
: ${strapi_url:="https://sub.domain.com"}
: ${strapi_target_dir:="/var/pm2node/$strapi_project_name"}
: ${strapi_repo_name:="$strapi_project_name"}
: ${strapi_add_gh_repo:=false}

set -e

yes | npx create-strapi-app@latest $strapi_project_name --quickstart --no-run
cd $strapi_project_name

# add production config
mkdir -p ./config/env/production
cat > ./config/env/production/server.js <<EOF
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
# pm2 kill
cd $strapi_target_dir
# yes | npx dotenv-vault login
# npx dotenv-vault pull production
npm install
npm run build
FILE=./.env.production
if [ -f "$FILE" ]; then
    echo "$FILE exists."
    pm2 start ecosystem.config.cjs
    pm2 save
fi
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

# add Strapi-Plugins

# install plugins
# plugin import-export-entries
npm i strapi-plugin-import-export-entries

cat > ./config/plugins.js <<EOF
module.exports = ({ env }) => ({
  //...
  "import-export-entries": {
    enabled: true,
  },
  config: {
    "users-permissions": {
      config: {
        jwtSecret: env('JWT_SECRET'),
      }
  },
    /**
     * Public hostname of the server.
     *
     * If you use the local provider to persist medias,
     * "serverPublicHostname" should be set to properly export media urls.
     */
    serverPublicHostname: "$strapi_url", // default: "".
  },
  //...
});
EOF

cat > ./src/admin/webpack.config.js <<EOF
'use strict';

const MonacoWebpackPlugin = require('monaco-editor-webpack-plugin');

module.exports = (config) => {
  config.plugins.push(new MonacoWebpackPlugin());

  return config;
};
EOF

rm ./config/middlewares.js
cat > ./config/middlewares.js <<EOF
module.exports = [
  "strapi::errors",
  "strapi::security",
  "strapi::cors",
  "strapi::poweredBy",
  "strapi::logger",
  "strapi::query",
  {
    name: "strapi::body",
    config: {
      jsonLimit: "10mb",
    },
  },
  "strapi::session",
  "strapi::favicon",
  "strapi::public",
];
EOF

# plugin plguin `sync-config`
npm install strapi-plugin-config-sync --save
rm ./config/admin.js
cat > ./config/admin.js <<EOF
module.exports = ({ env }) => ({
  auth: {
    secret: env("ADMIN_JWT_SECRET"),
  },
  apiToken: {
    salt: env("API_TOKEN_SALT"),
  },
  watchIgnoreFiles: ["**/config/sync/**"],
});
EOF

# remove unnecessary .env-file
rm ./.env.example

npm run build

if [ "$strapi_add_gh_repo" = true ] ; then
git init
git add .
git commit -m "first commit"
git branch -M main
gh repo create $strapi_repo_name --private
git remote add origin git@github.com:SMEETT/$strapi_repo_name.git
git push -u origin main
fi

# create .env.production and append content of .env
cat > .env.production <<EOF
# production
EOF
cat .env >> .env.production

npx dotenv-vault new
exec bash

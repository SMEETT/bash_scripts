#!/bin/bash
# VARS
: ${sveltekit_project_name:='sveltekit_test_1337'}
: ${sveltekit_url:="https://cms.borisfries.dev"}
: ${sveltekit_target_dir:="/var/lib/pm2node/$project_name"}
: ${sveltekit_repo_name:="$project_name"}
: ${sveltekit_add_gh_repo:=true}

set -e

# this doesn't work right now (known bug, prolly related to Win 11)
# npm create @svelte-add/kit@latest "$project_name" --with typescript+postcss+tailwindcss-forms+prettier

# add PM2 ecosystem config
cat > ./ecosystem.config.cjs <<EOF
module.exports = {
  apps: [
    {
      name: "$project_name",
      script: "./build/index.js",
      watch: false,
      ignore_watch: ["database"],
      autorestart: true,
      env: {
        NODE_ENV: "production",
        ENV_PATH: "$sveltekit_target_dir/.env.production",
      },
    },
  ],
};
EOF

# install adapter-node and create correct svelte.config.js
npm i -D @sveltejs/adapter-node
rm ./svelte.config.js
cat > ./svelte.config.js <<EOF
import preprocess from 'svelte-preprocess';
import adapter from '@sveltejs/adapter-node';

/** @type {import('@sveltejs/kit').Config} */
const config = {
	// Consult https://github.com/sveltejs/svelte-preprocess
	// for more information about preprocessors
	preprocess: [
		preprocess({
			postcss: true
		})
	],

	kit: {
		adapter: adapter({ out: 'build' })
	}
};

export default config;
EOF

rm ./tsconfig.json
cat > ./tsconfig.json <<EOF
{
	"extends": "./.svelte-kit/tsconfig.json",
	"compilerOptions": {
		"allowJs": true,
		"checkJs": true,
		"esModuleInterop": true,
		"forceConsistentCasingInFileNames": true,
		"resolveJsonModule": true,
		"skipLibCheck": true,
		"sourceMap": true,
		"strict": false
	}
}
EOF

#add deploy script
cat > ./deploy_script.sh <<EOF
pm2 kill
cd $sveltekit_target_dir
# yes | npx dotenv-vault login
# npx dotenv-vault pull production
npm install --production=false
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
          target: "$sveltekit_target_dir"

      # "appleboy/ssh-action@master" will run commands directly on the target machine (namely our VPS)
      - name: Build and Run
        uses: appleboy/ssh-action@master
        with:
          host: \${{ secrets.HOST }}
          USERNAME: \${{ secrets.USERNAME }}
          PORT: \${{ secrets.PORT }}
          KEY: \${{ secrets.SSHKEY }}
          script: sh $sveltekit_target_dir/deploy_script.sh
EOF

if [ "$add_gh_repo" = true ] ; then
git init
git add .
git commit -m "first commit"
git branch -M main
gh repo create $sveltekit_repo_name --private
git remote add origin git@github.com:SMEETT/$sveltekit_repo_name.git
git push -u origin main
fi
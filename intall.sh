#!/bin/bash
set -e

# config
export sveltekit_project_name='GVB_sveltekit'
export sveltekit_url="https://preview.berkenroth.info"
export sveltekit_target_dir="/var/pm2node/$sveltekit_project_name"
export sveltekit_repo_name="$sveltekit_project_name"
export sveltekit_add_gh_repo=true

export strapi_project_name='GVB_strapi'
export strapi_url="https://cms.berkenroth.info"
export strapi_target_dir="/var/pm2node/$strapi_project_name"
export strapi_repo_name="$strapi_project_name"
export strapi_add_gh_repo=true

echo ""
echo "--------------------"
echo "| SVELTEKIT config |" 
echo "--------------------"
echo "sveltekit_project_name: $sveltekit_project_name"
echo "sveltekit_url: $sveltekit_url"
echo "sveltekit_target_dir: $sveltekit_target_dir"
echo "sveltekit_repo_name: $sveltekit_repo_name"
echo "sveltekit_add_gh_repo: $sveltekit_add_gh_repo"
echo ""
echo "-----------------"
echo "| STRAPI config |"
echo "-----------------"
echo "strapi_project_name: $strapi_project_name"
echo "strapi_url: $strapi_url"
echo "strapi_target_dir: $strapi_target_dir"
echo "strapi_repo_name: $strapi_repo_name"
echo "strapi_add_gh_repo: $strapi_add_gh_repo"
echo ""
echo ""
read -p "Press enter to continue"
echo ""
echo "Installing SvelteKit..."
echo "executing 'install_sveltekit.sh'"

echo "----------------------------------------------------"
echo "SvelteKit Project name:" $sveltekit_project_name 
echo "----------------------------------------------------"
# this part is a workaround cause there's currently a known-bug in @svelte-add (sadly interactivity is needed for now). This means that the $sveltekit_project_name has to be entered correctly or the script will fail down the line.
npm create @svelte-add/kit@latest --legacy-peer-deps
# (printf "$sveltekit_project_name\n"; cat) | npm create @svelte-add/kit@latest
cp ./install_sveltekit.sh ./$sveltekit_project_name/
cd $sveltekit_project_name
./install_sveltekit.sh
# remove files and dirs we are going to replace
rm ./vite.config.js
rm ./svelte.config.js
rm ./tsconfig.json
rm -r ./src
rm ./install_sveltekit.sh
cd ..
cp -r ./sveltekit_base/. $sveltekit_project_names

echo ""
echo "Installing Strapi..."
echo "executing 'install_strapi.sh'"
./install_strapi.sh

echo "--------------------------------------------"
echo "IMPORTANT"
echo "RUN -->"
echo "npx dotenv-vault new"
echo "in /$sveltekit_project_name"
echo "--------------------------------------------"
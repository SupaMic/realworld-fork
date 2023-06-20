#!/bin/bash

# These should be done in order and before mix deps.get and mix compile

# Verify postgres database credentials because in some scenarios if the 
# docker image starts `FROM gitpod/workspace-postgres`, then it sometimes 
# seems to use `gitpod` as the default user and DB in Postgresql setup
DB_USER="postgres"
DB_NAME="postgres"

# Check if the user exists
user_exists=$(psql -U "$DB_USER" -d "$DB_NAME" -c "SELECT usename FROM pg_user WHERE usename='postgres';" -t)

if [[ -z "$user_exists" ]]; then
  echo "Creating '$DB_USER' user..."
  
  # Create the user
  echo "CREATE USER $DB_USER SUPERUSER; CREATE DATABASE $DB_NAME WITH OWNER $DB_USER;" | psql
  echo "'$DB_USER' user created successfully and made owner of $DB_NAME!"
else
  echo "'$DB_USER' user already exists."
fi;


echo "Checking Hex version...";
# check if HEX installed via asdf, and if not install
# Run mix hex.info, capture the output see if contains the expected information

if echo $(mix hex.info) | grep -q "Hex: "; then
  echo "Hex package manager is already installed."
else
  echo "Hex package manager is not installed. Installing...";
  mix local.hex --force;

  if [ $? -eq 0 ]; then
    echo "Hex package manager installed successfully."
  else
    echo "Failed to install Hex package manager."
  fi;
fi;

# Determine is if Rebar3 was installed properly using asdf
mix_path=$(asdf which mix)
mix_directory=$(dirname "$mix_path")
mix_directory=${mix_directory%/bin}  # Remove '/bin' from the end of the path

#Parsing to dermine the path of asdf install dir
elixir_version=$(elixir --version | grep -oE "Elixir [0-9]+\.[0-9]+\.[0-9]+" | awk '{print $2}')
major_version=$(echo "$elixir_version" | cut -d "." -f 1)
minor_version=$(echo "$elixir_version" | cut -d "." -f 2)
internal_mix_path="$mix_directory/.mix/elixir/$major_version-$minor_version"

rebar_bin_path="$internal_mix_path/rebar3"
rebar_info=$($rebar_bin_path -v)

if echo "$rebar_info" | grep -q "rebar 3."; then
  echo "Rebar3 package manager is already installed."
else
  echo "Rebar3 package manager is not installed. Installing..."
  mix local.rebar --force

  if [ $? -eq 0 ]; then
    echo "Rebar3 package manager installed successfully."
  else
    echo "Failed to install Rebar3 package manager."
  fi
fi

# This rebar section of the script could be replaced with the one-liner below if your Elixir version is 1.13 or greater
# mix local.rebar --if-missing

# However, I'll be keeping this longer version in gist a resource for determining dynamically the Elixir version and internal path routes 
# which might be useful for other deployment scenarios, especially if you want to '--force' a update a minor version, 
# then edit the line `"grep -q "rebar 3."` to the latest, ie change to `"grep -q "rebar 3.15"`


# This adds support for elixir-lsp.elixir-ls and victorbjorklund.phoenix extensions (in theory, but in practice the extensions themselves are unreliable)
json_file="/workspace/.vscode-remote/data/Machine/settings.json"
# Read the JSON file and add the new key-value pair
updated_json=$(jq '. + { "emmet.includeLanguages": { "phoenix-heex": "html", "html-eex": "html" } }' "$json_file")
# Write the updated JSON back to the file
echo "$updated_json" > "$json_file"
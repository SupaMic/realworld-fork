#!/bin/bash

# These should be done in order and before mix deps.get and mix compile

# Verify postgres database credentials because in some scenarios if the 
# docker image starts `FROM gitpod/workspace-postgres`, then it sometimes 
# seems to use `gitpod` as the default user and DB in Postgresql setup

# Check if the user exists
user_exists=$(psql -U gitpod -c "SELECT usename FROM pg_user WHERE usename='postgres';" -t)

if [[ -z "$user_exists" ]]; then
  echo "Creating postgres user to be compatible with default Elixir dev config..."
  
  # Create the user
  psql -U gitpod -c "CREATE USER postgres SUPERUSER;"
  psql -U gitpod -c "ALTER DATABASE postgres OWNER TO postgres;"
  psql -U gitpod -c "GRANT ALL PRIVILEGES ON DATABASE postgres TO gitpod;"
  echo "'postgres' user created successfully and made owner of 'postgres' db!"
else
  echo "'postgres' user already exists."
fi;

# force the install (--if-missing >= Elixir v1.13)
# mix local.hex --if-missing
# mix local.rebar --if-missing
mix local.hex
mix local.rebar

# check if HEX installed via asdf, and if not install
# Run mix hex.info, capture the output see if contains the expected information

echo "Checking Hex version in $MIX_HOME...";

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

# However, I'll be keeping this longer version in gist a resource for determining dynamically the Elixir version and internal path routes 
# which might be useful for other deployment scenarios like umbrellas

# This adds support for elixir-lsp.elixir-ls and victorbjorklund.phoenix extensions 
# (in theory, but in practice the extensions themselves are unreliable in the vscode-remote IDE)
json_file="/workspace/.vscode-remote/data/Machine/settings.json"
# Read the JSON file and add the new key-value pair
updated_json=$(jq '. + { "emmet.includeLanguages": { "phoenix-heex": "html", "html-eex": "html" } }' "$json_file")
# Write the updated JSON back to the file
echo "$updated_json" > "$json_file"
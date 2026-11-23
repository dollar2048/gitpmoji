#!/bin/bash

#script for installing gitpmoji. oneliner
# to run it as one liner you can use this command:
# curl -s https://raw.githubusercontent.com/Fl0p/gitpmoji/main/install.sh | bash

CURRENT_DIR=$(pwd)

#check if jq is installed
if ! command -v jq &> /dev/null
then
    echo "jq could not be found, installing it"
    brew install jq
fi

echo "Current dir: $CURRENT_DIR"

TOP_LEVEL_GIT_DIR=$(git rev-parse --show-toplevel 2>/dev/null || echo ".")

echo "Top level project dir: $TOP_LEVEL_GIT_DIR"
ls -la $TOP_LEVEL_GIT_DIR

echo "Enter dir name where gitpmoji scripts will be installed."
echo "Just press enter for default '.gitpmoji' or use '.' to install in project root"
read -p "GITPMOJI_DIR=" GITPMOJI_DIR

if [ -z "$GITPMOJI_DIR" ]; then
    GITPMOJI_DIR=".gitpmoji"
fi

if [ "$GITPMOJI_DIR" = "." ]; then
    GITPMOJI_INSTALL_DIR="$TOP_LEVEL_GIT_DIR"
    echo "gitpmoji will be installed in project root: $GITPMOJI_INSTALL_DIR"
else
    GITPMOJI_INSTALL_DIR="$TOP_LEVEL_GIT_DIR/$GITPMOJI_DIR"
    echo "gitpmoji will be installed in $GITPMOJI_INSTALL_DIR"
    mkdir -p $GITPMOJI_INSTALL_DIR
fi
cd $GITPMOJI_INSTALL_DIR
pwd

#download from github
curl -o prepare-commit-msg.sh https://raw.githubusercontent.com/Fl0p/gitpmoji/main/prepare-commit-msg.sh
curl -o gpt.sh https://raw.githubusercontent.com/Fl0p/gitpmoji/main/gpt.sh

#make executable
chmod +x prepare-commit-msg.sh
chmod +x gpt.sh

if [ "$GITPMOJI_DIR" != "." ]; then
    echo "*" > .gitignore
    echo "Created $GITPMOJI_DIR/.gitignore to ignore all files in this directory"
fi

#check if .gitpmoji.env exists
if [ -f .gitpmoji.env ]; then
    echo "$GITPMOJI_DIR/.gitpmoji.env already exists, skipping setup environment variables"
    echo "--- start of .gitpmoji.env ---"
    cat .gitpmoji.env
    echo "--- end of .gitpmoji.env ---"
else
    echo "Creating .gitpmoji.env file..."
    
    # Create file with header comment
    cat << 'EOF' > .gitpmoji.env
# gitpmoji environment configuration file
# This file contains environment variables for gitpmoji
# You can also create a global config file at ~/.gitpmoji.env
# Local settings in this file will override global settings from ~/.gitpmoji.env

EOF

    # Source global config if exists
    echo "# Source global config if exists" >> .gitpmoji.env
    echo "if [ -f ~/.gitpmoji.env ]; then" >> .gitpmoji.env
    echo "    source ~/.gitpmoji.env" >> .gitpmoji.env
    echo "fi" >> .gitpmoji.env
    echo "" >> .gitpmoji.env
    
    # Load global config to check for existing variables
    if [ -f ~/.gitpmoji.env ]; then
        source ~/.gitpmoji.env
        echo "Found global config at ~/.gitpmoji.env"
    fi
    
    # Asks for one variable and appends it to .gitpmoji.env.
    # If a global value exists (exported in the shell or set in ~/.gitpmoji.env),
    # pressing Enter keeps it: only a commented-out line is written, so the global value is used.
    # $1 variable name, $2 question, $3 default when there is no global value (may be empty),
    # $4 placeholder for the commented-out line
    ask_env_var() {
        local name=$1
        local question=$2
        local fallback=$3
        local placeholder=$4
        local global_value=${!name}
        local value

        if [ -n "$global_value" ]; then
            if [ "$name" = "GITPMOJI_API_KEY" ]; then
                # never print the secret itself
                echo "$question (press Enter to keep it, default is global)"
            else
                echo "$question (press Enter to keep it, default is global: '$global_value')"
            fi
            read -p "$name=" value
            if [ -z "$value" ]; then
                echo "#export $name=\"$placeholder\"" >> .gitpmoji.env
                return
            fi
        elif [ -n "$fallback" ]; then
            echo "$question (leave empty for default '$fallback')"
            read -p "$name=" value
            if [ -z "$value" ]; then
                value="$fallback"
            fi
        else
            echo "$question"
            read -p "$name=" value
        fi
        echo "export $name=\"$value\"" >> .gitpmoji.env
    }

    ask_env_var GITPMOJI_API_KEY \
        "Enter your OpenAI API key (https://platform.openai.com/account/api-keys)" \
        "" "_your_api_key_"
    ask_env_var GITPMOJI_API_BASE_URL \
        "Enter base url for OpenAI API" \
        "https://api.openai.com/v1" "https://api.openai.com/v1"
    ask_env_var GITPMOJI_API_MODEL \
        "Enter model for OpenAI API" \
        "gpt-4o" "gpt-4o"
    
    # Process GITPMOJI_PREFIX_RX
    if [ -n "$GITPMOJI_PREFIX_RX" ]; then
        echo "Global GITPMOJI_PREFIX_RX found: $GITPMOJI_PREFIX_RX"
        echo "Use global GITPMOJI_PREFIX_RX? (y/n, default is 'yes')"
        read USE_GLOBAL_PREFIX
        if [ "$USE_GLOBAL_PREFIX" != "n" ]; then
            echo "#export GITPMOJI_PREFIX_RX=\"\"" >> .gitpmoji.env
        else
            echo "Enter prefix for commit messages which will be untouched as first keyword for each message"
            echo "In format of sed RegExp use double backslash (\\\\) for escaping special symbols like {, }, ?, etc."
            read -p "GITPMOJI_PREFIX_RX=" prefix
            echo "export GITPMOJI_PREFIX_RX=\"$prefix\"" >> .gitpmoji.env
        fi
    else
        echo "Enter prefix for commit messages which will be untouched as first keyword for each message"
        echo "In format of sed RegExp use double backslash (\\\\) for escaping special symbols like {, }, ?, etc."
        read -p "GITPMOJI_PREFIX_RX=" prefix
        echo "export GITPMOJI_PREFIX_RX=\"$prefix\"" >> .gitpmoji.env
    fi
    
    # Process GITPMOJI_MULTILINE_COMMIT
    if [ -n "$GITPMOJI_MULTILINE_COMMIT" ]; then
        echo "Global GITPMOJI_MULTILINE_COMMIT found: $GITPMOJI_MULTILINE_COMMIT"
        echo "Use global GITPMOJI_MULTILINE_COMMIT? (y/n, default is 'yes')"
        read USE_GLOBAL_MULTILINE_COMMIT
        if [ "$USE_GLOBAL_MULTILINE_COMMIT" != "n" ]; then
            echo "#export GITPMOJI_MULTILINE_COMMIT=\"false\"" >> .gitpmoji.env
        else
            echo "Use multiple lines for generated commit messages instead of a single short line? (y/n, default is 'no')"
            read USE_MULTILINE_COMMIT
            if [ "$USE_MULTILINE_COMMIT" = "y" ]; then
                multiline_commit="true"
            else
                multiline_commit="false"
            fi
            echo "export GITPMOJI_MULTILINE_COMMIT=\"$multiline_commit\"" >> .gitpmoji.env
        fi
    else
        echo "Use multiple lines for generated commit messages instead of a single short line? (y/n, default is 'no')"
        read USE_MULTILINE_COMMIT
        if [ "$USE_MULTILINE_COMMIT" = "y" ]; then
            multiline_commit="true"
        else
            multiline_commit="false"
        fi
        echo "export GITPMOJI_MULTILINE_COMMIT=\"$multiline_commit\"" >> .gitpmoji.env
    fi

    echo ".gitpmoji.env created successfully"
    echo "--- start of .gitpmoji.env ---"
    cat .gitpmoji.env
    echo "--- end of .gitpmoji.env ---"
fi

# A custom dir is already fully ignored by its own .gitignore ("*").
# In the project root there is no such file, so always ignore .gitpmoji.env to keep the API key secret.
if [ "$GITPMOJI_DIR" = "." ] && ! grep -qxF ".gitpmoji.env" "$TOP_LEVEL_GIT_DIR/.gitignore" 2>/dev/null; then
    echo "" >> "$TOP_LEVEL_GIT_DIR/.gitignore"
    echo "# ignore environment file for gitpmoji" >> "$TOP_LEVEL_GIT_DIR/.gitignore"
    echo ".gitpmoji.env" >> "$TOP_LEVEL_GIT_DIR/.gitignore"
    echo "Added .gitpmoji.env to .gitignore to keep your API key secret"
fi

cd $TOP_LEVEL_GIT_DIR

echo "Gitpmoji files installed in: $GITPMOJI_INSTALL_DIR"


HOOKS_DIR="$TOP_LEVEL_GIT_DIR/.git/hooks"
echo "git hooks dir: $HOOKS_DIR"

echo "Going to install git hook for prepare-commit-msg"

mkdir -p "$HOOKS_DIR"
cd $HOOKS_DIR

# Simple relative path: from .git/hooks go up twice (../../) then into GITPMOJI_DIR
if [ "$GITPMOJI_DIR" = "." ]; then
    SYMLINK_PATH="../../prepare-commit-msg.sh"
else
    SYMLINK_PATH="../../$GITPMOJI_DIR/prepare-commit-msg.sh"
fi

echo "Creating symlink for prepare-commit-msg"
echo "ln -sf $SYMLINK_PATH prepare-commit-msg"

ln -sf $SYMLINK_PATH prepare-commit-msg

cd $TOP_LEVEL_GIT_DIR

echo "Git hooks successfully installed"
echo "You can now commit with gitpmoji. 🚀"
echo "To uninstall just remove $HOOKS_DIR/prepare-commit-msg and $GITPMOJI_INSTALL_DIR"
echo ""
# -d reads the diff from stdin, -g makes the commit message, -e adds the emoji.
# The -m line works even when there are no changes yet (empty diff).
echo "Run this to test:"
echo "  git diff | $GITPMOJI_DIR/gpt.sh -d -g -e"
echo "or, without a diff:"
echo "  $GITPMOJI_DIR/gpt.sh -e -m \"Fix login crash\""

exit 0

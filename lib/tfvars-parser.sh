#!/bin/bash
# Terraform variables file parser
# Parses _variables.tf to extract variable definitions

# Parse a _variables.tf file and extract variable names
# Arguments: $1 = path to _variables.tf
# Returns: newline-separated list of variable names
parse_all_variables() {
    local file="$1"

    if [[ ! -f "$file" ]]; then
        log_error "Variables file not found: $file"
        return 1
    fi

    # Extract variable names using grep and sed
    grep -E '^variable\s+"[^"]+"' "$file" | \
        sed -E 's/^variable\s+"([^"]+)".*/\1/'
}

# Parse a _variables.tf file and extract variables WITHOUT defaults
# These are the required variables that need values from vault
# Arguments: $1 = path to _variables.tf
# Returns: newline-separated list of required variable names
parse_required_variables() {
    local file="$1"

    if [[ ! -f "$file" ]]; then
        log_error "Variables file not found: $file"
        return 1
    fi

    # Use awk to parse HCL and find variables without default
    awk '
    /^variable\s+"[^"]+"/ {
        # Extract variable name
        match($0, /"([^"]+)"/, arr)
        current_var = arr[1]
        has_default = 0
        brace_count = 0
        in_variable = 1
    }

    in_variable && /{/ {
        brace_count++
    }

    in_variable && /}/ {
        brace_count--
        if (brace_count == 0) {
            # End of variable block
            if (!has_default && current_var != "") {
                print current_var
            }
            in_variable = 0
            current_var = ""
        }
    }

    in_variable && /^\s*default\s*=/ {
        has_default = 1
    }
    ' "$file"
}

# Parse a _variables.tf file and extract variables WITH defaults
# These are optional variables
# Arguments: $1 = path to _variables.tf
# Returns: newline-separated list of optional variable names
parse_optional_variables() {
    local file="$1"

    if [[ ! -f "$file" ]]; then
        log_error "Variables file not found: $file"
        return 1
    fi

    # Use awk to parse HCL and find variables with default
    awk '
    /^variable\s+"[^"]+"/ {
        match($0, /"([^"]+)"/, arr)
        current_var = arr[1]
        has_default = 0
        brace_count = 0
        in_variable = 1
    }

    in_variable && /{/ {
        brace_count++
    }

    in_variable && /}/ {
        brace_count--
        if (brace_count == 0) {
            if (has_default && current_var != "") {
                print current_var
            }
            in_variable = 0
            current_var = ""
        }
    }

    in_variable && /^\s*default\s*=/ {
        has_default = 1
    }
    ' "$file"
}

# Find _variables.tf files in a directory
# Arguments: $1 = directory path
# Returns: newline-separated list of _variables.tf paths
find_variables_files() {
    local dir="$1"

    if [[ ! -d "$dir" ]]; then
        log_error "Directory not found: $dir"
        return 1
    fi

    find "$dir" -maxdepth 1 -name "_variables.tf" -o -name "variables.tf" 2>/dev/null
}

# Get variable type from _variables.tf
# Arguments: $1 = path to _variables.tf, $2 = variable name
# Returns: variable type (string, number, bool, map, list, etc.)
get_variable_type() {
    local file="$1"
    local var_name="$2"

    if [[ ! -f "$file" ]]; then
        echo "string"
        return
    fi

    # Use awk to find the type of a specific variable
    awk -v var="$var_name" '
    $0 ~ "^variable\\s+\"" var "\"" {
        in_variable = 1
        brace_count = 0
    }

    in_variable && /{/ {
        brace_count++
    }

    in_variable && /}/ {
        brace_count--
        if (brace_count == 0) {
            in_variable = 0
        }
    }

    in_variable && /^\s*type\s*=/ {
        match($0, /type\s*=\s*(.+)/, arr)
        type = arr[1]
        gsub(/^\s+|\s+$/, "", type)
        print type
        exit
    }
    ' "$file"
}

# Check if a variable is marked as sensitive
# Arguments: $1 = path to _variables.tf, $2 = variable name
# Returns: 0 if sensitive, 1 if not
is_variable_sensitive() {
    local file="$1"
    local var_name="$2"

    if [[ ! -f "$file" ]]; then
        return 1
    fi

    # Use awk to check if variable has sensitive = true
    awk -v var="$var_name" '
    $0 ~ "^variable\\s+\"" var "\"" {
        in_variable = 1
        brace_count = 0
    }

    in_variable && /{/ {
        brace_count++
    }

    in_variable && /}/ {
        brace_count--
        if (brace_count == 0) {
            exit 1
        }
    }

    in_variable && /^\s*sensitive\s*=\s*true/ {
        exit 0
    }

    END {
        exit 1
    }
    ' "$file"
}

# Prompt the user for their choice
echo "Which stage would you like to build?"
echo "1. R or Both R & Python (No GPU) - For USE_R or USE_R & USE_PYTHON (choose R Base Image in config.env)"
echo "2. Python with GPU - For USE_PYTHON with GPU requirements (choose GPU Base Image in config.env)"
echo "3. Python without GPU - For USE_PYTHON without GPU requirements (choose Python Base Image in config.env)"
echo "4. Both R & Python with GPU - For USE_R & USE_PYTHON with GPU requirements (choose GPU Base Image in config.env)"
read -p "Enter your choice (1, 2, 3, or 4): " choice

# Define the start and end markers for each section
markers=(
    "##ARG_SECTION" "##ARG_SECTION_ENDS_HERE"
)

# Function to extract lines between markers
extract_section() {
    local start_marker=$1
    local end_marker=$2
    sed -n "/$start_marker/,/$end_marker/p" $3
}

## changes discussion #######

replace_base_image() {
    image_name=$1
    # Extract and combine the sections
    output=""

    output+=$(extract_section ${markers[2]} ${markers[3]} ./docker/Dockerfile_setup )$'\n\n'

    output+=$(extract_section ${markers[0]} ${markers[1]} ./docker/config.env )$'\n\n'

    output+=$(extract_section ${markers[4]} ${markers[5]} ./docker/Dockerfile_setup )$'\n\n'

    # Write the combined output to a temporary Dockerfile
    echo "$output" > "./docker/Dockerfile"

    ## Replace the placeholder PLATFORM and BASE_IMAGE with values in the Dockerfile_base.
    image_value=$(grep "^ARG $image_name=" ./docker/config.env | cut -d '=' -f 2)
    sed -i '' "s|\${$image_name}|$image_value|g" ./docker/Dockerfile

    PLATFORM=$(grep '^ARG PLATFORM=' ./docker/config.env | cut -d '=' -f 2)
    sed -i '' "s|\${PLATFORM}|$PLATFORM|g" ./docker/Dockerfile
}


# Validate input and build the selected stage
case $choice in
    1)
        echo "Building R stage..."
        TAG="r_stage"
        markers+=("##STAGE_1_R_BASE_IMAGE"  "##STAGE_1_BASE_IMAGE_ENDS_HERE"  "##STAGE_1_DEPENDENCIES"  "##STAGE_1_ENDS_HERE")
        replace_base_image "R_BASE_IMAGE"
        ;;
    2)
        echo "Building Python stage with GPU..."
        TAG="py_gpu_stage"
        markers+=("##STAGE_2_PYTHON_WITH_GPU_BASE_IMAGE"  "##STAGE_2_BASE_IMAGE_ENDS_HERE" "##STAGE_2_DEPENDENCIES"   "##STAGE_2_ENDS_HERE" )
        replace_base_image "GPU_BASE_IMAGE"
        ;;
    3)
        echo "Building Python stage without GPU..."
        TAG="py_stage"
        markers+=("##STAGE_3_PYTHON_WITHOUT_GPU_BASE_IMAGE"  "##STAGE_3_BASE_IMAGE_ENDS_HERE" "##STAGE_3_DEPENDENCIES" "#STAGE_3_ENDS_HERE" )
        replace_base_image "PYTHON_BASE_IMAGE"
        ;;
    4)
        echo "Building Both R and Python with GPU stage..."
        TAG="r_py_gpu_stage"
        markers+=("##STAGE_4_BOTH_R_AND_PYTHON_WITH_GPU_BASE_IMAGE" "##STAGE_4_BASE_IMAGE_ENDS_HERE" "##STAGE_4_DEPENDENCIES"  "#STAGE_4_ENDS_HERE" )
        replace_base_image "GPU_BASE_IMAGE"
        ;;

    *)
        echo "Invalid choice. Please enter 1, 2, 3, or 4."
        exit 1
        ;;
esac

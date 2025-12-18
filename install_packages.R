# R dependencies installation script
required_packages <- c("tidyverse", "tidytext", "ggplot2", "dplyr", "stringr", "readr")

# Check if packages are installed and install them if not
new_packages <- required_packages[!(required_packages %in% installed.packages()[,"Package"])]
if(length(new_packages)) install.packages(new_packages)

print("All R libraries installed successfully!")

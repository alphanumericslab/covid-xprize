Recommended way to run the predictors in AlphanumericsTeam/predictors is to install the virtual envirnoment based on requirements.txt in the root of the repo.

Run the run.sh script to install a fresh virtual environment in the root folder.
The script expects a python version greater than or equal to 3.6 in the host system.
Currently the run.sh script directly calls python3.7 to make the virtual environment.
This can be changed to the version of python installed in the host system.

commands to run


1. chmod +x run.sh
2. ./run.sh

The run.sh script also adds root of the repo to the the PYTHONPATH in virtual envirnoment.
This allows developer to directly import from any module in the repo in the following manner for instance

`from AlphanumericsTeam.predictors.lstm.util import holiday_country`

To maintian the code it is advised that all subfolders  have `__init__.py` file for module import-ing in this manner.

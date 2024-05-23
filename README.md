# terradactyl
TerraDactyl allows for the extraction of map layer data, currently curated by Google Earth Engine (GEE), at a set of point in space and time. It has been developed in tandem with [eDNAExplorer.org](https://www.ednaexplorer.org) as a means of automatically associated biodiversity data, derived from environmental DNA, with environmental conditions associated with each sample. However, these extracted environmental data can be associated with other types of data collected, not just biodiversity measurements. 

## Setup
Install requirements
   `pip install -r requirements.txt`
   
Install parallel
   `sudo apt install parallel`
   
Note: You will need to pass the GEE Credentials as parameters or change the variable at the top of [terradactyl.sh](https://github.com/eDNA-Explorer/terradactyl/blob/main/terradactyl.sh)
  
## Workflow
### Input data format.
Provide an input CSV file containing the following information for each sample. An example input file is located [here](https://github.com/eDNA-Explorer/terradactyl/blob/main/TerraDactyl_ExampleInput.csv).:

Longitude/Latitude: In decimal degrees north and east.

Sample Date: The date associated with each sample. The default format is YYYY-MM-DD.

Sample ID: A unique identifier for each sample.

Spatial Uncertainty: The uncertainty in position, in meters, associated with each point. If no value is provided, or if the uncertainty provided is under 30 meters, then a default value of 30 meters will be assigned.

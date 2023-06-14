#
#
#   This is a wrapper script which is intended to be edited with cluster-IDs so that it can call
#   the script to cancel the FakeQuakes run with that ID. (so that that script can be called strictly
#   via python code, no terminal required)

import cancel_fakequakes_from_vdc_v2_4

clusterID = 23976591 

cancel_fakequakes_from_vdc_v2_4.cancel(clusterID)

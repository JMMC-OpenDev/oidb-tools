This material is dedicated to:
- build a mirror of an oidb instance
- generate some plots submitting new datalink to an oidb instance

Requirements:
- OIFitsExplorer.jar (run installOIFitsExplorer.sh if not present)


An OiDB instance is considered as the master database of metadata given to a
collection of oifits. OiDB manages its own record IDs (one per granule)

If an external tools try to update some metadata it must send back to OiDB the
initial composite key elements (target, instrument, date, oifits)

more 1yr_report_address.csv | grep "mimosa" | grep ",,75.0" | perl -pe 's/(.*)\/mimosa.*/$1/' > mimosa_75_paths
more 1yr_report_address.csv | grep "mimosa" | grep ",,100.0" | perl -pe 's/(.*)\/mimosa.*/$1/' > mimosa_100_paths
cat mimosa_100_paths mimosa_75_paths > mimosa_100_and_75_paths

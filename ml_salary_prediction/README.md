# Data Visualization

![](https://github.com/dennisholee/SparkDojo/blob/master/ml_salary_prediction/ML_SALARY_PREDICTION.png)

# Setup environment

## Upload file to HDFS
```shell
./hadoop fs -mkdir -p /user/dennis/ml_salary_prediction/
./hadoop fs -put ~/Dev/SPARK/SparkDojo/ml_salary_prediction/Salary_Data.csv /user/dennis/ml_salary_prediction
```

# Error
```shell
org.apache.hadoop.hdfs.server.common.InconsistentFSStateException: Directory /tmp/hadoop-dennis/dfs/name is in an inconsistent state: storage directory does not exist or is not accessible.
```

```shell
./hadoop namenode -format
```

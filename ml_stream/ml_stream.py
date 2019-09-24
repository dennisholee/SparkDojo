from pyspark.sql import SparkSession
from pyspark import SparkContext
from pyspark.ml.regression import LinearRegression
from pyspark.ml.feature import VectorAssembler

# Assumes the file is loaded to HDFS
salarydata_file = '/user/dennis/ml_salary_prediction/Salary_Data.csv'

spark = SparkSession.builder.master('local').getOrCreate()

salary_dataframe = spark.read.format('CSV').option('header', 'true').option('inferSchema', 'true').load(salarydata_file)
salary_dataframe.printSchema()

assembler = VectorAssembler(inputCols=['YearsExperience'], outputCol='features')

data = assembler.transform(salary_dataframe)

train, test = data.randomSplit([0.7, 0.3])
train.printSchema()

algo = LinearRegression(featuresCol='features', labelCol='Salary', maxIter=10, regParam=0.3, elasticNetParam=0.8)

model = algo.fit(train)

# Print the coefficients and intercept for linear regression
print('---------------------------------')

print('Coefficient: %s' % str(model.coefficients))
print('Intercept: %s' % str(model.intercept))

# Summarize the model over the training set and print out some metrics
trainingSummary = model.summary
print('numIterations: %d' % trainingSummary.totalIterations)
print('objectiveHistory: %s' % str(trainingSummary.objectiveHistory))
trainingSummary.residuals.show()
print('RMSE: %f' % trainingSummary.rootMeanSquaredError)
print('r2: %f' % trainingSummary.r2)
print('---------------------------------')

predictions = model.transform(test)
predictions.printSchema()
predictions.select('YearsExperience', 'Salary', 'prediction').show()

years = data.select('YearsExperience').collect()
salary = data.select('Salary').collect()

predictYears = predictions.select('YearsExperience').collect()
predictSalary = predictions.select('prediction').collect()

import matplotlib.pyplot as plt

plt.scatter(years, salary)
plt.plot(predictYears, predictSalary) 
plt.show()


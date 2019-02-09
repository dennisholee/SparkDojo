from pyspark import SparkContext


licenseFilePath = "file:///home/dennis/Dev/SPARK/SparkDojo/linecount/hello.txt"

sc = SparkContext("local", appName="linecount")

licenseData = sc.textFile(licenseFilePath).cache()

lineLength = licenseData.map(lambda x: 1)
lineLength.persist()

totalLength = lineLength.reduce(lambda a, b: a + b)

print("Line count: %i" % totalLength)

FROM apache/zeppelin:0.8.2

RUN apt-get update
RUN apt-get install -y --no-install-recommends \
  less \
  vim

RUN wget https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-common/3.2.1/hadoop-common-3.2.1.jar -P /zeppelin/interpreter/jdbc/
RUN wget https://repo1.maven.org/maven2/org/apache/hive/hive-jdbc/3.1.2/hive-jdbc-3.1.2.jar -P /zeppelin/interpreter/jdbc/
RUN wget https://repo1.maven.org/maven2/org/apache/hive/hive-service-rpc/3.1.2/hive-service-rpc-3.1.2.jar -P /zeppelin/interpreter/jdbc/
RUN wget https://repo1.maven.org/maven2/org/apache/hive/hive-service/3.1.2/hive-service-3.1.2.jar -P /zeppelin/interpreter/jdbc/
RUN wget https://repo1.maven.org/maven2/org/apache/curator/curator-client/4.2.0/curator-client-4.2.0.jar -P /zeppelin/interpreter/jdbc/
RUN wget https://repo1.maven.org/maven2/org/apache/hive/hive-common/3.1.2/hive-common-3.1.2.jar -P /zeppelin/interpreter/jdbc/
RUN wget https://repo1.maven.org/maven2/org/apache/hive/hive-serde/3.1.2/hive-serde-3.1.2.jar -P /zeppelin/interpreter/jdbc/
RUN wget https://repo1.maven.org/maven2/com/google/guava/guava/10.0.1/guava-10.0.1.jar -P /zeppelin/interpreter/jdbc/

COPY files/interpreter.json /zeppelin/conf/

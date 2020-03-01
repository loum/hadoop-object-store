##################
Data Kafka Connect
##################

`Kafka Connect <https://docs.confluent.io/current/connect/index.html#>`_ is a framework for scalable and reliable connections from Kafka to external systems.

At a high level, the main concepts in Kafka Connect are the **workers** and **connectors**:

- Kafka Connect **workers** execute tasks within a pipeline
- Kafka Connect **connectors** define where data should be copied to and from.  Data flows into and out of Kafka are defined as source and sinks.  There are many common connectors available which can all be driven via configuration.

Kafka Connect provides:

- Performance via scalable and parallelisable tasks (to *N* Kakfa partitions)
- Fault tolerance by managing worker state redistribution on failures
- Highly available distributed service (or standalone for small implementations)
- Low latency (2 x AWS ECS m5.large can process ~15M records in approximately one minute)

*************
Prerequisites
*************

* `Docker <https://docs.docker.com/install/>`_

***************
Getting Started
***************

Get the code::

    $ git clone https://github.com/loum/data-kafka-connect && cd data-kafka-connect

.. note::

    Run all commands from the top-level directory of the `git` repository.

Get the `Makester project <https://github.com/loum/makester.git>`_::

    $ git submodule update --remote --merge

************
Getting Help
************

There should be a `make` target to be able to get most things done.  Check the help for more information::

    $ make help

********************
Development Pipeline
********************

Setup the environment::

    $ make init

The following example demonstrates how we can stream data from Kafka into S3 using an Apache Kafka Connect.

Kafka to S3 Workflow
====================

Bring up the cluster with a Kafka Conenct worker in distributed mode::

    $ make local-build-up

Register the Sample Avro Schema
===============================

The Kafka Schema Registry manages the Avro schema sample Avro messages.  It offers a REST API at port ``8081`` that allows us to register the schema with ``curl``::

    $ curl -X POST -H "Content-Type: application/vnd.schemaregistry.v1+json" \
      --data @data-kafka-connect/files/schemas/develop/sample-sink-avro-schema.json \
      http://localhost:8081/subjects/sample-sink-value/versions
     
    {"id":1}

Here, we have registered the schema under a subject named ``sample-sink-value``.  The convention used by the serializers to register schemas under a name that follows the ``<topic>-(key|value)`` format.

The Kafka Schema Registry response value denotes the ID of the schema.  Schema versions can be checked any time with the command::

    $ curl http://localhost:8081/subjects/sample-sink-value/versions/
     
    [1]

Detailed output can be achieved by specifying the schema version number::

    $ curl http://localhost:8081/subjects/sample-sink-value/versions/1 | jq .
     
    {
      "subject": "sample-sink-value",
      "version": 1,
      "id": 1,
      "schema": "{\"type\":\"record\",\"name\":\"KafkaEvent\",\"namespace\":\"com.lfs.cm.interpreters\", ...}"
    }

Create a Message Producer
=========================

Use the Kafka REST Proxy API to produce records::

    $ curl -X POST -H "Content-Type: application/vnd.kafka.avro.v2+json" \
      -H "Accept: application/vnd.kafka.v2+json" \
      --data '{"value_schema_id": 1, "records": [{"value": {"data": {"Id": "98cf1dc6-6f2b-4d9d-b733-f45e7d71aded"}}}]}' \
      http://localhost:8082/topics/sample-sink
     
    {"offsets":[{"partition":0,"offset":0,"error_code":null,"error":null}],"key_schema_id":null,"value_schema_id":1}

Consume the Messages (Optional)
===============================

Kakfa REST Proxy API also allows you to consume the messages.  First, create the consumer. This particular example will create a consumer for Avro data starting at the beginning of the topic's log::

    $ curl -X POST -H "Content-Type: application/vnd.kafka.v2+json" \
      --data '{"name": "my_consumer_instance", "format": "avro", "auto.offset.reset": "earliest"}' \
      http://localhost:8082/consumers/my_avro_consumer
    
    {"instance_id":"my_consumer_instance","base_uri":"http://kafka-rest:8082/consumers/my_avro_consumer/instances/my_consumer_instance"}

Next, subscribe to the ``sample-sink`` topic::

    $ curl -X POST -H "Content-Type: application/vnd.kafka.v2+json" --data '{"topics":["sample-sink"]}' \
      http://localhost:8082/consumers/my_avro_consumer/instances/my_consumer_instance/subscription

Consume messages from the topic.  This is decoded, translated to JSON and included in the response.  The schema used for deserialization is fetched automatically from schema registry::

    $ curl -X GET -H "Accept: application/vnd.kafka.avro.v2+json" \
      http://localhost:8082/consumers/my_avro_consumer/instances/my_consumer_instance/records

Finally, clean up::

    $ curl -X DELETE -H "Content-Type: application/vnd.kafka.v2+json" \
      http://localhost:8082/consumers/my_avro_consumer/instances/my_consumer_instance

Sink to S3
==========

For demonstration purposes and to avoid AWS interfaces during PoC, we will be using MINIO as the sink.  Navigate to `<http://127.0.0.1:9000>`_ and login with the hardwired test credentials.

.. note::

    The following are TEST credentials only that were auto-generated by the MINIO docker container on initial start up and re-used here for simplicity.  **Do not use these credentials in a production environment.**

**Access Key:** ``05Y2TVZ3T1RQNH7TI89Q``

**Secret Key:** ``8P2AajiFu+CHo2+3M2pUgWBhtVLaYUXBqBjGZ3wP``

Once logged in you should see the ``sample-sink`` bucket.

Kafka Connect uses connectors to move data in and out of infrastructure components.  Source and sink are conventions used within Kafka Connect to identify data moving into Kakfa (source) and data moving out of Kakfa (sink).

Kafka Connect exposes a REST API on port ``28083`` that can be used to interact with the service.

The ``bootstrap`` facility in the project deployment will creates a Kafka Connect sink into S3.  Bootstrap will simulate the following curl command::

    $ curl -X POST -H "Content-Type: application/json" \
      --data @./data-kafka-connect/files/connectors/properties/sample-sink-connector.s3.properties.json \
      http://localhost:28083/connectors | jq .
     
    {
      "name": "sample-sink",
      "config": {
        "name": "sample-sink",
        "connector.class": "io.confluent.connect.s3.S3SinkConnector",
        "tasks.max": "1",
        "topics": "sample-sink",
        "topics.dir": "sample-sink",
        "s3.part.size": "5242880",
        "flush.size": "1",
        "s3.bucket.name": "sample-sink",
        "store.url": "http://minio:9000",
        "storage.class": "io.confluent.connect.s3.storage.S3Storage",
        "format.class": "io.confluent.connect.s3.format.json.JsonFormat",
        "schema.generator.class": "io.confluent.connect.storage.hive.schema.DefaultSchemaGenerator",
        "partitioner.class": "io.confluent.connect.storage.partitioner.DailyPartitioner",
        "locale": "en-AU",
        "timezone": "UTC",
        "timestamp.extractor": "Record",
        "rotate.schedule.interval.ms": "60000",
        "schema.compatibility": "NONE"
      },
      "tasks": [],
      "type": "sink"
    }

This will also start the sink to S3.  Check the MINIO dashboard to see the messages present in JSON format.

Use the Kafka Connect service to also query the list of available connectors::

    $ curl http://localhost:28083/connectors
     
    [sample-sink]

Cleanup
=======

Remove the containers and data::

    $ make local-build-down

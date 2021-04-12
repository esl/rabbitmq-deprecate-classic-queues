# RabbitMQ Deprecate Classic Queues

With the emergence of Quorum Queues in RabbitMQ 3.8.x, operators are now seeking means of being able disable the use of Classic Queues within their RabbitMQ environments with minimal service impact. This plugin allows operators to disable the use of Classic Queues on RabbitMQ installations.

**NOTE:** For use on clustered environments, this plugin must be activated/enabled on ALL cluster nodes. 


## Usage

1. Download the **rabbitmq\_deprecate\_classic\_queues\-\<VERSION\>.ez** file from the [project's releases page](https://github.com/Ayanda-D/rabbitmq-deprecate-classic-queues/releases).
2. Copy the **rabbitmq_deprecate\_classic\_queues\-<VERSION>.ez** to the RabbitMQ's installation plugin directory

 ```
cp rabbitmq_deprecate_classic_queues-3.8.0.ez  <RABBITMQ-HOME-PATH>/rabbitmq_server-3.8.14/plugins/
```


3. To deprecate classic queues, enable the plugin

 ```
rabbitmq-plugins enable rabbitmq_deprecate_classic_queues
```



## Testing

To execute automated tests, close the plugin and run the following command:


```
make tests
```


## LICENSE

(c) Erlang Solutions Ltd, 2021

https://www.erlang-solutions.com/
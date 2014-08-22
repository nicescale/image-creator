# 用户机器上的变量

### 全局变量
路径： ```/etc/puppet/pdata/modules/.global.json```

同一个项目下，所有机器上的全局变量文件内容完全相同。

文件格式如下 ：

```javascript
{
  "service-id-1": {
    "meta": {
      "tags": [
        "master"
      ],
      "cluster_id": "mysqlcluster",
      "deploy_tags":{
          "image_version": "5.6",
          "image_name": "percona-mysql",
          "service_name": "mysql",
          "role": "master"
      }
    },
    "mysql": {
      "port": 3306
    }
  },
  "service-id-2": {
    "meta": {
      "tags": [
        "slave"
      ],
      "cluster_id": "mysqlcluster"
      "deploy_tags":{
          "image_version": "5.6",
          "image_name": "percona-mysql",
          "service_name": "mysql",
          "role": "slave"
      }
    },
    "mysql": {
      "port": 3307
    }
  }
}
```

其中JSON中的key表示service_id，value是对应service的全局变量。

### 服务变量
服务中未提取为全局变量的变量，保存在部署有这个服务的机器上的
```ruby
'/etc/puppet/pdata/modules/%s.json' % service_id
```

格式如下：

```javascript
{
  "meta": {
    "global": {
      "meta": [
        "cluster_id",
        "service_id",
        "tag"
      ],
      "redis": [
        "port",
        "dir"
      ]
    },
    "tags": [
      "redis",
      "slave"
    ]
  },
  "redis": {
    "port": "6379",
    "timeout": "0",
    "tcp_keepalive": "60",
    "logfile": "",
    "databases": "16",
    "save": [
      {
        "changes": "1",
        "interval": "900"
      },
      {
        "changes": "10",
        "interval": "300"
      },
      {
        "changes": "10000",
        "interval": "60"
      }
    ]
  }
}
```

### 该机器上运行了哪些服务？
文件： ```/etc/puppet/pdata/manifest```

格式：

```javascript
{
  "modules": {
    "service_id": {
      "status": "enable",
      "seq": 10
    }
  },
  "fingerprint": "c38962184ff1b965bf5242359e677e57",
  "role": "redis_slave",
  "vsn": 2
}
```

从中取modules的key即可得到运行于该机器上的所有服务的ID


### 获取各种变量的方法
提供了以下API：

```ruby
  def get_service_var(service_id, key, namespace = nil)
  def get_cluster_var(cluster_id, role, key, namespace = nil)
  def get_auto_var_by_service(service_id, key)
  def get_auto_var_by_cluster(cluster_id, role, key)
  def get_global_var_by_service(service_id, key, namespace = nil)
  def get_global_var_by_cluster(cluster_id, role, key, namespace = nil)
  def services_on_this_instance
  def services_in_this_project
```

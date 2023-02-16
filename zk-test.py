from kazoo.client import KazooClient

if __name__ == "__main__":
    zk = KazooClient(hosts="192.168.132.31:2181,192.168.132.32:2181,192.168.132.47:2181")
    zk.start()

    # test 1: ls
    child = zk.get_children("/")
    print("> ls /")
    print(child)

    # test 2: create and get
    zk.create("/mynode", b"mydata")
    print("> create /mynode \"mydata\"")
    mynode = zk.get("/mynode")
    print("> get /mynode")
    print(mynode)

    # test 3: delete
    zk.delete("/mynode")
    print("> delete /mynode")

    # test 4: ls again
    child = zk.get_children("/")
    print("> ls /")
    print(child)

    zk.stop()
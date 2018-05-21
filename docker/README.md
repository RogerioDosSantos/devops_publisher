
# rogersantos/ubuntu-x86 image

- To execute this image please follow the steps below to create a helper script

```bash
docker run --rm rogersantos/publisher > rogersantos-publisher
chmod +x rogersantos-publisher
```

- Then you can use the script as following:

`rogersantos-publisher <command>` 

Examples: 
   `rogersantos-publisher pwd`
   `rogersantos-publisher ls`
   `rogersantos-publisher sh`

 **Note**: Your current folder will be automatically mapped the /work folder 
 on the container. The work folder is also the default folder.



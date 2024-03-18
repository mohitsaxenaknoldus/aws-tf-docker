## Terraform Module to Deploy Hello World Java (Maven-based) App To AWS ECS

### Setup

1. Install Maven: `sudo apt install maven`
2. Create a Hello World project using:

```groovy
mvn archetype:generate -DgroupId=com.example -DartifactId=helloworld -DarchetypeArtifactId=maven-archetype-quickstart -DinteractiveMode=false
```

3. Create Dockerfile
4. Build Dockerfile: `docker built -t java-mvn-hello-world .`
5. Push image to ECR:

```

```
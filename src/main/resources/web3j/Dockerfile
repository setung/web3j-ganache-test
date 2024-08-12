# Use a base image with OpenJDK and Gradle installed
FROM gradle:7.6.0-jdk11 AS builder

# Install web3j CLI
RUN curl -L https://get.web3j.io | sh

# Set working directory
WORKDIR /app

# Copy your solidity files and build configuration
COPY . .

# Run the web3j command inside the Docker container
RUN web3j generate solidity \
    -b src/main/kotlin/org/example/web3jtest/contracts/erc721/output/MsNftV1CollectionCreator.bin \
    -a src/main/kotlin/org/example/web3jtest/contracts/erc721/output/MsNftV1CollectionCreator.abi \
    -o src/main/kotlin \
    -p org.example.web3jtest.contracts.erc721.wrapper

# Final stage
FROM openjdk:11-jre-slim

# Set working directory
WORKDIR /app

# Copy the generated files from the builder stage
COPY --from=builder /app/src/main/kotlin/org/example/web3jtest/contracts/erc721/wrapper /app/src/main/kotlin/org/example/web3jtest/contracts/erc721/wrapper

CMD ["bash"]

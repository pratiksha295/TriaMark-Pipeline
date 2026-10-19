FROM astrocrpublic.azurecr.io/runtime:3.3-9

# Java 17 for PySpark (same major version TriMark_STEP_Spark runs on locally).
# The runtime's Debian (trixie) only packages Java 21, so copy a Temurin 17 JRE in.
COPY --from=eclipse-temurin:17-jre /opt/java/openjdk /opt/java/openjdk
ENV JAVA_HOME=/opt/java/openjdk
ENV PATH="${JAVA_HOME}/bin:${PATH}"

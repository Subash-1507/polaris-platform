# Jenkins controller: pinned LTS on JDK 21 with plugins baked into the image.
# All configuration comes from JCasC (../casc), so there is no setup wizard.
FROM jenkins/jenkins:2.580.2-jdk25

COPY --chown=jenkins:jenkins plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN jenkins-plugin-cli --plugin-file /usr/share/jenkins/ref/plugins.txt

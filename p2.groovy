import groovy.xml.MarkupBuilder

def metadataWriter = new StringWriter()
def metadataXml = new MarkupBuilder(metadataWriter)
/**************
<?xml version='1.0' encoding='UTF-8'?>
<?compositeMetadataRepository version='1.0.0'?>
<repository name='&quot;Eclipse Project Test Site&quot;'
    type='org.eclipse.equinox.internal.p2.metadata.repository.CompositeMetadataRepository' version='1.0.0'>
  <properties size='1'>
    <property name='p2.timestamp' value='1243822502499'/>
  </properties>
  <children size='4'>
    <child location='../eclipse/updates/3.7milestones/S-3.7RC5-201106131736'/>
    <child location='../eclipse/org/releases/indigo/current'/>
    <child location='../spring/org/springframework/current'/>
    <child location='../springdm/org/springframework/osgi/current'/>
  </children>
</repository>
**************/
metadataXml.repository('name':'&quot;Eclipse Project Test Site&quot;','type':'org.eclipse.equinox.internal.p2.metadata.repository.CompositeMetadataRepository', 'version':'1.0.0'){
    properties(size:'1') {
        property(name:'p2.timestamp', value:'1243822502499')
    }
    children(size:'4') {
        child(location:'../eclipse/updates/3.7milestones/S-3.7RC5-201106131736')
	child(location:'../eclipse/org/releases/indigo/current')
	child(location:'../spring/org/springframework/current')
	child(location:'../springdm/org/springframework/osgi/current')
    }
}

def metadataStr = "<?xml version='1.0' encoding='UTF-8'?>\n"
metadataStr+="<?compositeMetadataRepository version='1.0.0'?>\n"
metadataStr+=metadataWriter.toString()
println metadataStr

File metadataFile = new File("compositeContent.xml")
PrintWriter pw = new PrintWriter(metadataFile) 
pw.write(metadataStr)  
pw.close() 

def artifactWriter = new StringWriter()
def artifactXml = new MarkupBuilder(artifactWriter)
/**************
<?xml version='1.0' encoding='UTF-8'?>
<?compositeArtifactRepository version='1.0.0'?>
<repository name='&quot;Eclipse Project Test Site&quot;'
    type='org.eclipse.equinox.internal.p2.artifact.repository.CompositeArtifactRepository' version='1.0.0'>
  <properties size='1'>
    <property name='p2.timestamp' value='1243822502440'/>
  </properties>
  <children size='4'>
    <child location='../eclipse/updates/3.7milestones/S-3.7RC5-201106131736'/>
    <child location='../eclipse/org/releases/indigo/current'/>
    <child location='../spring/org/springframework/current'/>
    <child location='../springdm/org/springframework/osgi/current'/>
  </children>
</repository>
**************/
artifactXml.repository('name':'&quot;Eclipse Project Test Site&quot;','type':'org.eclipse.equinox.internal.p2.artifact.repository.CompositeArtifactRepository', 'version':'1.0.0'){
    properties(size:'1') {
        property(name:'p2.timestamp', value:'1243822502499')
    }
    children(size:'4') {
        child(location:'../eclipse/updates/3.7milestones/S-3.7RC5-201106131736')
	child(location:'../eclipse/org/releases/indigo/current')
	child(location:'../spring/org/springframework/current')
	child(location:'../springdm/org/springframework/osgi/current')
    }
}

def artifactStr = "<?xml version='1.0' encoding='UTF-8'?>\n"
artifactStr+="<?compositeMetadataRepository version='1.0.0'?>\n"
artifactStr+=artifactWriter.toString()
println artifactStr

File artifactFile = new File("compositeArtifacts.xml")
PrintWriter artifactpw = new PrintWriter(artifactFile) 
artifactpw.write(artifactStr)
artifactpw.close() 

def props = new Properties()
new File("version_built.properties").withInputStream { 
  stream -> props.load(stream) 
}
// accessing the property from Properties object using Groovy's map notation
println "version=" + props["version"]

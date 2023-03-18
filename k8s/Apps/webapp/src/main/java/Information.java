import io.quarkus.runtime.annotations.RegisterForReflection;

@RegisterForReflection
public class Information {

    private String path;
    private String host;
    private String from;
    private String version;

    public Information() {
    }

    public Information(String path, String host, String from, String version) {
        this.path = path;
        this.host = host;
        this.from = from;
        this.version = version;
    }

    public String getPath() {
        return path;
    }

    public String getHost() {
        return host;
    }

    public String getFrom() {
        return from;
    }

    public void setPath(String path) {
        this.path = path;
    }

    public void setHost(String host) {
        this.host = host;
    }

    public void setFrom(String from) {
        this.from = from;
    }

    public void setVersion(String version) {
        this.version = version;
    }

    public String getVersion() {
        return version;
    }

}

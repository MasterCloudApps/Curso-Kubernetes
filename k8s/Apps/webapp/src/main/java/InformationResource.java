
import io.vertx.core.http.HttpServerRequest;
import org.eclipse.microprofile.config.inject.ConfigProperty;

import javax.ws.rs.GET;
import javax.ws.rs.Path;
import javax.ws.rs.core.Context;
import javax.ws.rs.core.Response;
import javax.ws.rs.core.UriInfo;

import org.jboss.logging.Logger;

@Path("/")
public class InformationResource {

    private static final Logger LOG = Logger.getLogger(InformationResource.class);

    @Context
    private HttpServerRequest request;

    @Context
    private UriInfo info;

    @ConfigProperty(name = "quarkus.application.version")
    private String version;

    @GET
    public Response getInfo() {

        String host = this.request.localAddress().toString();
        String path = this.info.getPath();
        String remote = this.request.remoteAddress().hostAddress();

        LOG.info("Request " + host + path + " from IP " + remote);

        return Response.ok(new Information(path, host, remote, this.version)).build();
    }

}
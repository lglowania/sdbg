package com.github.sdbg.integration.jdt.gwt;

import com.github.sdbg.integration.jdt.SDBGJDTIntegrationPlugin;

import java.io.IOException;
import java.net.MalformedURLException;
import java.net.URI;
import java.net.URISyntaxException;
import java.util.Map;

import org.eclipse.core.resources.IMarker;
import org.eclipse.core.resources.IProject;
import org.eclipse.core.resources.IResource;
import org.eclipse.core.resources.IResourceDelta;
import org.eclipse.core.resources.IncrementalProjectBuilder;
import org.eclipse.core.runtime.CoreException;
import org.eclipse.core.runtime.IProgressMonitor;
import org.json.JSONException;
import org.json.JSONObject;

public class GWTSDMBuilder extends IncrementalProjectBuilder {
  public static final String BUILDER_ID = SDBGJDTIntegrationPlugin.PLUGIN_ID + ".gwtsdmbuilder";

  private static final String MARKER_TYPE = SDBGJDTIntegrationPlugin.PLUGIN_ID + ".gwtsdmmarker";

  public GWTSDMBuilder() {
  }

  @Override
  protected IProject[] build(int kind, Map<String, String> args, IProgressMonitor monitor)
      throws CoreException {
    if (kind == FULL_BUILD) {
      fullBuild(monitor);
    } else {
      IResourceDelta delta = getDelta(getProject());
      if (delta == null) {
        fullBuild(monitor);
      } else {
        incrementalBuild(delta, monitor);
      }
    }
    return null;
  }

  @Override
  protected void clean(IProgressMonitor monitor) throws CoreException {
    getProject().deleteMarkers(MARKER_TYPE, true, IResource.DEPTH_INFINITE);
  }

  protected void fullBuild(final IProgressMonitor monitor) throws CoreException {
    GWTSDMProperties properties = new GWTSDMProperties(getProject());
    GWTSDMCodeServerAPI codeServerAPI = properties.isRecompileEnabled()
        ? getCodeServerAPI(properties) : null;
    if (codeServerAPI == null) {
      return;
    }

    try {
      JSONObject result = codeServerAPI.recompile(monitor);

      if (!"ok".equals(result.getString("status"))) {
        IMarker marker = getProject().createMarker(MARKER_TYPE);
        marker.setAttribute(IMarker.MESSAGE, "GWT SDM recompilation failed for module "
            + codeServerAPI.getModule() + ". Please check your SDM Code Server logs for details");
        marker.setAttribute(IMarker.SEVERITY, IMarker.SEVERITY_ERROR);
      } else {
        getProject().deleteMarkers(MARKER_TYPE, true, IResource.DEPTH_INFINITE);
        notifyBuildCompleted(properties, codeServerAPI);
      }
    } catch (JSONException e) {
      throw SDBGJDTIntegrationPlugin.wrapError(e);
    } catch (MalformedURLException e) {
      throw SDBGJDTIntegrationPlugin.wrapError(e);
    } catch (IOException e) {
      throw SDBGJDTIntegrationPlugin.wrapError(e);
    }
  }

  protected void incrementalBuild(IResourceDelta delta, IProgressMonitor monitor)
      throws CoreException {
    fullBuild(monitor);
  }

  private GWTSDMCodeServerAPI getCodeServerAPI(GWTSDMProperties properties) {
    try {
      return new GWTSDMCodeServerAPI(new URI(
          "http",
          null,
          properties.getCodeServerHost(),
          properties.getCodeServerPort(),
          "/",
          null,
          null), properties.getModuleName());
    } catch (CoreException e) {
      throw new RuntimeException(e);
    } catch (URISyntaxException e) {
      throw new RuntimeException(e);
    }
  }

  private void notifyBuildCompleted(GWTSDMProperties properties, GWTSDMCodeServerAPI codeServerAPI)
      throws MalformedURLException, IOException, JSONException, CoreException {
    if (properties.isChromeLiveEditEnabled()) {
      for (GWTSDMDOMResourceTracker tracker : GWTSDMDOMResourceTracker.getInitialized()) {
        if (getProject() != null && tracker.getProject() != null
            && getProject().getName().equals(tracker.getProject().getName())) {
          tracker.uploadLatestScript(codeServerAPI);
        }
      }
    }
  }
}

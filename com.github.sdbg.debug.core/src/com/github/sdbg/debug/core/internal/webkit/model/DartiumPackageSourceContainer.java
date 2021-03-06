/*
 * Copyright (c) 2013, the Dart project authors.
 * 
 * Licensed under the Eclipse Public License v1.0 (the "License"); you may not use this file except
 * in compliance with the License. You may obtain a copy of the License at
 * 
 * http://www.eclipse.org/legal/epl-v10.html
 * 
 * Unless required by applicable law or agreed to in writing, software distributed under the License
 * is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express
 * or implied. See the License for the specific language governing permissions and limitations under
 * the License.
 */
package com.github.sdbg.debug.core.internal.webkit.model;

import com.github.sdbg.debug.core.SDBGLaunchConfigWrapper;

import org.eclipse.core.runtime.CoreException;
import org.eclipse.debug.core.DebugPlugin;
import org.eclipse.debug.core.ILaunchConfiguration;
import org.eclipse.debug.core.sourcelookup.ISourceContainerType;
import org.eclipse.debug.core.sourcelookup.containers.AbstractSourceContainer;

/**
 * A source container for Dartium that resolves package: urls to resources or files
 */
public class DartiumPackageSourceContainer extends AbstractSourceContainer {

  public static final String TYPE_ID = DebugPlugin.getUniqueIdentifier() + ".containerType.file"; //$NON-NLS-1$

  SDBGLaunchConfigWrapper wrapper;

  public DartiumPackageSourceContainer(ILaunchConfiguration launchConfig) {
    wrapper = new SDBGLaunchConfigWrapper(launchConfig);
  }

  @Override
  public Object[] findSourceElements(String name) throws CoreException {
//&&&    
//    if (!name.startsWith("package:")) {
//      return EMPTY;
//    }
//
//    IContainer parent = wrapper.getProject();
//
//    if (wrapper.getApplicationResource() != null) {
//      parent = wrapper.getApplicationResource().getParent();
//    }
//
//    IFileInfo fileInfo = DartCore.getProjectManager().resolveUriToFileInfo(parent, name);
//
//    if (fileInfo != null) {
//      if (fileInfo.getResource() != null) {
//        return new Object[] {fileInfo.getResource()};
//      } else {
//        return new Object[] {new LocalFileStorage(fileInfo.getFile())};
//      }
//    }
//
    return EMPTY;
  }

  @Override
  public String getName() {
    return "Package sources";
  }

  @Override
  public ISourceContainerType getType() {
    return getSourceContainerType(TYPE_ID);
  }

}

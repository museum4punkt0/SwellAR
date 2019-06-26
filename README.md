#  SwellAR

### Table of Contents  
- [Description](#Description)  
- [Technical Documentation and Installing](#Technical-Documentation-and-Installing)
- [Contributing](#Contributing)  
- [Credits](#Credits) 
- [Licensing](#Licensing) 

## Description
An augmented reality ocean currents visualization prototype. 

This prototype is part of the project museum4punkt0 - Digital Stra-tegies for the Museum of the Future, sub-project Rethinking Visitor Journeys. Further information: www.museum4punkt0.de/en/.  

The project museum4punkt0 is funded by the Federal Government Commissioner for Cul-ture and the Media in accordance with a resolution issued by the German Bundestag (Par-liament of the Federal Republic of Germany).

## Technical Documentation and Installing
### Dependencies

The app depends on a few external libraries. We use [Carthage](https://github.com/Carthage/Carthage) for dependency management. Once you have installed Carthage, run `carthage bootstrap` to install the dependencies.

#### Vuforia

We use **Vuforia 7.1.34** for AR tracking. The library needs to be put into the `vuforia-sdk-ios` subdirectory. Specifically, the `build` folder from the [Vuforia SDK](https://developer.vuforia.com/downloads/sdk) needs to be present.

> Note: The Vuforia license key needs to be put in the app's SwellAR/Info.plist under `VuforiaLicenseKey`.
     
### Augmented Reality

`ARViewController`, and the contents of the `Vuforia` directory, are stripped-down parts of the augmented reality Refrakt Engine. Basically just enough to get target recognition going, but sufficient for our purposes. See the class documentation in `ARViewController.swift`.

The `VuforiaDataSets` directory contains the target databases that are loaded by the app on startup. These have to be created by the [Vuforia Target Manager](https://developer.vuforia.com/target-manager)

#### `Map.swift`

The `Map` class manages the rendering of ocean currents and tappable points-of-interest on top of a real-life map target. Each target gets one `Map` object. The top-level `Maps` directory contains a subdirectory for each map target. Each of these target directories contains the following files:

- `config.json`
Configures various particle simulation parameters. See the code for more information on each parameter (in particular `ParticleScreen.swift` and `ParticleState.swift`).

- `mask.png` 
*Optional.* A mask texture to ensure that islands are not covered by simulated particles. This is sometimes necessary due to the coarse nature of the underlying ocean current data.

- `touch_items.json` 
*Optional.*  Describes tappable points-of-interest that can trigger videos/photos/text. The format is pretty self-explanatory and reminiscent of HTML image maps with circular areas. The `href`s are relative to the top-level `Media` directory.

- `OceanCurrents`
A subdirectory containing ocean current textures and metadata. It has an `index.json` that describes the lat/lon bounds of the relevant ocean section. Note that these are given as raw indexes into OSCAR arrays, as described below.

### Particle Simulation

The ocean current simulation is based on [webgl-wind](https://github.com/mapbox/webgl-wind), a global visualisation of wind power. The underlying data format on which the simulation is based is obivously different, and certain details had to be changed, but the basic principle is the same: 

- Ocean current velocities are encoded in a current texture. This is done once, beforehand, based on OSCAR data (`OceanCurrents.swift` and `OceanCurrents+OSCAR.swift`).
- The particle positions are computed in an OpenGL shader and encoded into a state texture (`ParticleState.swift`).
- The state texture, together with the current texture and a color ramp, is used to draw the particles, adding a fade effect (`ParticleScreen.swift`).

### OSCAR/PODAAC

The ocean currents data in OSCAR format is fetched from the open access PODAAC server hosted by NASA. The format is reasonably well documented, but there is one particular issue that is a bit tricky: requests have to be specified in terms of indexes into lat/lon arrays, instead of directly giving the desired lat/lon coordinates. The formulas for this conversion are given in `PODAAC.swift`.

#### oscarmap

This Xcode project contains an additional target: `oscarmap`, in the subdirectory of the same name. It is a very simple but handy little tool that lets you download OSCAR data directly from the PODAAC server. The data is processed, and stored as a PNG plus metadata in the user's Downloads directory, and can be used directly by the app. This is how the default datasets that ship with the app were created.

> Note: the lat/lon bounds taken by the tool are the raw OSCAR indexes as described above.

## Contributing
If you'd like to contribute, please fork the repository and use a feature branch. Pull requests are warmly welcome.

## Credits
Contracting entity: Staatliche Museen zu Berlin - Preußischer Kulturbesitz

Design and Programming: Refrakt in colaboration with museum4punkt0

## Licensing

BSD 3-Clause License

Copyright (c) 2018, museum4punkt0 / Refrakt

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this
  list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice,
  this list of conditions and the following disclaimer in the documentation
  and/or other materials provided with the distribution.

* Neither the name of the copyright holder nor the names of its
  contributors may be used to endorse or promote products derived from
  this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

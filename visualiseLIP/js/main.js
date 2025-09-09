/**
 * Main Three.js application for LIP visualization
 * Handles scene setup, camera controls, and main render loop
 */

console.log('Loading main.js module...');

// Import modules with error handling
let THREE, OrbitControls, LIPGeometry, LIPMaterials, LIPLabels, LIPControls;
let modulesLoaded = false;

async function loadModules() {
    try {
        console.log('Loading Three.js modules...');
        const [threeModule, orbitModule, geometryModule, materialsModule, labelsModule, controlsModule] = await Promise.all([
            import('three'),
            import('three/addons/controls/OrbitControls.js'),
            import('./geometry.js'),
            import('./materials.js'),
            import('./labels.js'),
            import('./controls.js')
        ]);
        
        THREE = threeModule;
        OrbitControls = orbitModule.OrbitControls;
        LIPGeometry = geometryModule.LIPGeometry;
        LIPMaterials = materialsModule.LIPMaterials;
        LIPLabels = labelsModule.LIPLabels;
        LIPControls = controlsModule.LIPControls;
        
        modulesLoaded = true;
        console.log('All modules loaded successfully');
        return true;
    } catch (error) {
        console.error('Failed to load modules:', error);
        return false;
    }
}

class LIPVisualization {
    constructor() {
        this.scene = null;
        this.camera = null;
        this.renderer = null;
        this.controls = null;
        this.lipGeometry = null;
        this.lipMaterials = null;
        this.lipLabels = null;
        this.lipControls = null;
        this.data = null;
        this.boundingBox = { min: { x: 0, y: 0, z: 0 }, max: { x: 10, y: 10, z: 10 } };
    }

    async init() {
        console.log('Initializing LIP visualization...');
        
        // The new interface handles loading states
        
        // Try to load Three.js modules
        if (!modulesLoaded) {
            const success = await loadModules();
            if (!success) {
                console.warn('Three.js modules failed to load, upload interface still available');
                return;
            }
        }
        
        // Initialize Three.js components only if modules loaded successfully
        try {
            this.initScene();
            this.initCamera();
            this.initRenderer();
            this.initControls();
            this.initLighting();
            console.log('Three.js components initialized');
        } catch (error) {
            console.error('Failed to initialize Three.js components:', error);
        }
        
        console.log('Initialization complete');
    }
    
    async initWithData(data) {
        try {
            console.log('=== DEBUG: initWithData called ===');
            console.log('Data keys:', Object.keys(data));
            console.log('Vertices count:', data.vertices ? data.vertices.length : 'missing');
            console.log('Facets count:', data.facets ? data.facets.length : 'missing');
            
            if (data.vertices && data.vertices.length > 0) {
                console.log('First 3 vertices:', data.vertices.slice(0, 3));
            }
            
            if (data.facets && data.facets.length > 0) {
                console.log('First 3 facets:', data.facets.slice(0, 3));
                const facet4v = data.facets.find(f => f.length === 4);
                if (facet4v) {
                    console.log('First 4-vertex facet:', facet4v);
                }
            }
            
            this.data = data;
            
            // Update bounding box from actual data
            if (this.data.vertices && this.data.vertices.length > 0) {
                this.updateBoundingBox();
            }
            
            // Ensure modules are loaded before proceeding
            if (!modulesLoaded) {
                console.log('Modules not loaded, loading them now...');
                const success = await loadModules();
                if (!success) {
                    throw new Error('Failed to load Three.js modules. Please refresh the page and try again.');
                }
            }
            
            // Ensure Three.js components are initialized
            if (!this.scene || !this.camera || !this.renderer) {
                console.log('Three.js components not initialized, initializing now...');
                this.initScene();
                this.initCamera();
                this.initRenderer();
                this.initControls();
                this.initLighting();
            } else {
                // Update existing camera and controls with new bounding box
                this.updateCameraAndControls();
            }
            
            // Initialize LIP-specific components with the loaded data
            this.lipGeometry = new LIPGeometry(this.data);
            this.lipMaterials = new LIPMaterials();
            this.lipLabels = new LIPLabels(this.data, this.camera, this.renderer);
            this.lipControls = new LIPControls();
            
            // Create the visualization
            await this.createVisualization();
            
            // Setup UI
            this.setupUI();
            
            // Start render loop
            this.animate();
            
            // Visualization is ready - the new interface handles UI updates
            
            console.log('LIP Visualization initialized successfully');
            window.dispatchEvent(new CustomEvent('lipVisualizationReady'));
        } catch (error) {
            console.error('Error initializing LIP visualization:', error);
            this.showError('Failed to initialize visualization: ' + error.message);
        }
    }

    async loadData() {
        try {
            const response = await fetch('./data/LIP.json');
            if (!response.ok) {
                throw new Error(`HTTP ${response.status}: ${response.statusText}`);
            }
            this.data = await response.json();
            
            // Update bounding box from data if available
            if (this.data.vertices && this.data.vertices.length > 0) {
                this.updateBoundingBox();
            }
            
            console.log('Loaded LIP data:', {
                vertices: this.data.vertices?.length || 0,
                facets: this.data.facets?.length || 0,
                labels: this.data.labels?.length || 0,
                bundles: this.data.bundles?.length || 0
            });
        } catch (error) {
            throw new Error(`Failed to load LIP.json: ${error.message}`);
        }
    }

    updateBoundingBox() {
        const vertices = this.data.vertices;
        const min = new THREE.Vector3(Infinity, Infinity, Infinity);
        const max = new THREE.Vector3(-Infinity, -Infinity, -Infinity);
        
        vertices.forEach(vertex => {
            min.x = Math.min(min.x, vertex[0]);
            min.y = Math.min(min.y, vertex[1]);
            min.z = Math.min(min.z, vertex[2]);
            max.x = Math.max(max.x, vertex[0]);
            max.y = Math.max(max.y, vertex[1]);
            max.z = Math.max(max.z, vertex[2]);
        });
        
        this.boundingBox = { min, max };
        console.log('Updated bounding box:', this.boundingBox);
    }

    updateCameraAndControls() {
        const box = this.boundingBox;
        const size = new THREE.Vector3().subVectors(box.max, box.min);
        const center = new THREE.Vector3().addVectors(box.min, box.max).multiplyScalar(0.5);
        const maxSize = Math.max(size.x, size.y, size.z);
        
        // Update camera position and look-at
        this.camera.position.set(
            center.x + maxSize * 1.5,
            center.y + maxSize * 1.5,
            center.z + maxSize * 1.5
        );
        this.camera.lookAt(center);
        
        // Update camera far plane
        this.camera.far = maxSize * 10;
        this.camera.updateProjectionMatrix();
        
        // Update controls target to the actual center of the data
        if (this.controls) {
            this.controls.target.copy(center);
            this.controls.update();
        }
        
        // Update axes helper size and position - origin at (0,0,0), rotation center at cube center
        if (this.axesHelper) {
            this.scene.remove(this.axesHelper);
            this.axesHelper = new THREE.AxesHelper(maxSize * 0.8);
            this.axesHelper.name = 'axes-helper';
            this.axesHelper.position.set(box.min.x, box.min.y, box.min.z); // Position at origin (0,0,0)
            this.scene.add(this.axesHelper);
            console.log('Updated axes helper size to:', maxSize * 0.8, 'positioned at origin');
        }
        
        console.log('Updated camera and controls center to:', center);
    }

    initScene() {
        if (!modulesLoaded || !THREE) return;
        
        this.scene = new THREE.Scene();
        this.scene.background = new THREE.Color(0xf0f0f0);
        
        // Add coordinate system helper - use a reasonable default size initially
        this.axesHelper = new THREE.AxesHelper(5); // Default size, will update later
        this.axesHelper.name = 'axes-helper';
        this.scene.add(this.axesHelper);
        console.log('Added axes helper to scene');
    }

    initCamera() {
        if (!modulesLoaded || !THREE) return;
        
        const box = this.boundingBox;
        const size = new THREE.Vector3().subVectors(box.max, box.min);
        const center = new THREE.Vector3().addVectors(box.min, box.max).multiplyScalar(0.5);
        const maxSize = Math.max(size.x, size.y, size.z);
        
        this.camera = new THREE.PerspectiveCamera(
            75,
            window.innerWidth / window.innerHeight,
            0.1,
            maxSize * 10
        );
        
        // Position camera to view the entire bounding box
        this.camera.position.set(
            center.x + maxSize * 1.5,
            center.y + maxSize * 1.5,
            center.z + maxSize * 1.5
        );
        this.camera.lookAt(center);
    }

    initRenderer() {
        if (!modulesLoaded || !THREE) return;
        
        this.renderer = new THREE.WebGLRenderer({ antialias: true });
        this.renderer.setSize(window.innerWidth, window.innerHeight);
        this.renderer.setPixelRatio(window.devicePixelRatio);
        this.renderer.shadowMap.enabled = true;
        this.renderer.shadowMap.type = THREE.PCFSoftShadowMap;
        
        document.getElementById('canvas-container').appendChild(this.renderer.domElement);
    }

    initControls() {
        if (!modulesLoaded || !OrbitControls) return;
        
        this.controls = new OrbitControls(this.camera, this.renderer.domElement);
        
        // Set target to center of bounding box
        const center = new THREE.Vector3().addVectors(this.boundingBox.min, this.boundingBox.max).multiplyScalar(0.5);
        this.controls.target.copy(center);
        
        this.controls.enableDamping = true;
        this.controls.dampingFactor = 0.05;
        this.controls.enableZoom = true;
        this.controls.enablePan = true;
        this.controls.enableRotate = true;
    }

    initLighting() {
        if (!modulesLoaded || !THREE) return;
        
        // Ambient light for overall illumination
        const ambientLight = new THREE.AmbientLight(0x404040, 0.6);
        this.scene.add(ambientLight);
        
        // Directional light for shadows and definition
        const directionalLight = new THREE.DirectionalLight(0xffffff, 0.8);
        const box = this.boundingBox;
        const center = new THREE.Vector3().addVectors(box.min, box.max).multiplyScalar(0.5);
        const size = new THREE.Vector3().subVectors(box.max, box.min);
        const maxSize = Math.max(size.x, size.y, size.z);
        
        directionalLight.position.set(
            center.x + maxSize,
            center.y + maxSize,
            center.z + maxSize
        );
        directionalLight.target.position.copy(center);
        directionalLight.castShadow = true;
        
        // Configure shadow camera
        directionalLight.shadow.camera.left = -maxSize;
        directionalLight.shadow.camera.right = maxSize;
        directionalLight.shadow.camera.top = maxSize;
        directionalLight.shadow.camera.bottom = -maxSize;
        directionalLight.shadow.camera.near = 0.1;
        directionalLight.shadow.camera.far = maxSize * 3;
        directionalLight.shadow.mapSize.width = 2048;
        directionalLight.shadow.mapSize.height = 2048;
        
        this.scene.add(directionalLight);
        this.scene.add(directionalLight.target);
    }

    async createVisualization() {
        // Clear existing visualization objects (but keep axes and lights)
        const objectsToRemove = [];
        this.scene.traverse((object) => {
            if (object.isMesh || object.isPoints || object.isGroup) {
                // Don't remove axes helper or lights
                if (!object.isAxisHelper && !object.isLight) {
                    objectsToRemove.push(object);
                }
            }
        });
        objectsToRemove.forEach(obj => this.scene.remove(obj));
        
        // Create polyhedral geometry
        const geometries = this.lipGeometry.createFacetGeometries();
        const materials = this.lipMaterials.createFacetMaterials(geometries.length);
        
        // Add facets to scene
        geometries.forEach((geometry, index) => {
            if (geometry.vertices.length >= 3) {
                const mesh = this.lipGeometry.createFacetMesh(geometry, materials[index]);
                if (mesh) {
                    mesh.castShadow = true;
                    mesh.receiveShadow = true;
                    this.scene.add(mesh);
                }
            }
        });
        
        // Add vertex markers
        const vertexGeometry = this.lipGeometry.createVertexGeometry();
        const vertexMaterial = this.lipMaterials.createVertexMaterial();
        const vertexMesh = new THREE.Points(vertexGeometry, vertexMaterial);
        this.scene.add(vertexMesh);
        
        // Add edge visualization for debugging (1D facets)
        const edgeGeometry = this.lipGeometry.createEdgeGeometry();
        if (edgeGeometry.attributes.position.count > 0) {
            const edgeMaterial = new THREE.LineBasicMaterial({ 
                color: 0x00ff00, 
                linewidth: 2,
                transparent: true,
                opacity: 0.6
            });
            const edgeMesh = new THREE.LineSegments(edgeGeometry, edgeMaterial);
            edgeMesh.name = 'polyhedral-edges';
            this.scene.add(edgeMesh);
            console.log('Added', edgeGeometry.attributes.position.count / 2, 'polyhedral edges');
        }
        
        // Add bounding box faces
        this.addBoundingBoxFaces();
        
        // Add labels
        this.lipLabels.createLabels();
        this.lipLabels.addToScene(this.scene);
    }

    setupUI() {
        this.lipControls.setupUI({
            onTransparencyChange: (value) => {
                this.lipMaterials.updateTransparency(value);
            },
            onToggleWireframe: (enabled) => {
                this.lipMaterials.toggleWireframe(enabled);
            },
            onToggleLabels: (enabled) => {
                this.lipLabels.toggleVisibility(enabled);
            },
            onToggleAxes: (enabled) => {
                this.toggleAxes(enabled);
            },
            onViewPreset: (preset) => {
                this.setViewPreset(preset);
            }
        });
    }

    setViewPreset(preset) {
        const center = new THREE.Vector3().addVectors(this.boundingBox.min, this.boundingBox.max).multiplyScalar(0.5);
        const size = new THREE.Vector3().subVectors(this.boundingBox.max, this.boundingBox.min);
        const maxSize = Math.max(size.x, size.y, size.z);
        const distance = maxSize * 2;
        
        let position;
        switch (preset) {
            case 'front':
                position = new THREE.Vector3(center.x, center.y, center.z + distance);
                break;
            case 'back':
                position = new THREE.Vector3(center.x, center.y, center.z - distance);
                break;
            case 'left':
                position = new THREE.Vector3(center.x - distance, center.y, center.z);
                break;
            case 'right':
                position = new THREE.Vector3(center.x + distance, center.y, center.z);
                break;
            case 'top':
                position = new THREE.Vector3(center.x, center.y + distance, center.z);
                break;
            case 'bottom':
                position = new THREE.Vector3(center.x, center.y - distance, center.z);
                break;
            case 'isometric':
            default:
                position = new THREE.Vector3(
                    center.x + distance * 0.7,
                    center.y + distance * 0.7,
                    center.z + distance * 0.7
                );
                break;
        }
        
        // Animate camera to new position
        this.animateCamera(position, center);
    }

    animateCamera(targetPosition, targetLookAt) {
        const duration = 1000; // ms
        const startPosition = this.camera.position.clone();
        const startTarget = this.controls.target.clone();
        const startTime = performance.now();
        
        const animate = (currentTime) => {
            const elapsed = currentTime - startTime;
            const progress = Math.min(elapsed / duration, 1);
            
            // Smooth easing function
            const eased = progress * progress * (3 - 2 * progress);
            
            // Interpolate position
            this.camera.position.lerpVectors(startPosition, targetPosition, eased);
            
            // Interpolate target
            this.controls.target.lerpVectors(startTarget, targetLookAt, eased);
            
            this.controls.update();
            
            if (progress < 1) {
                requestAnimationFrame(animate);
            }
        };
        
        requestAnimationFrame(animate);
    }

    toggleAxes(visible) {
        if (this.axesHelper) {
            this.axesHelper.visible = visible;
        }
    }

    addBoundingBoxFaces() {
        const box = this.boundingBox;
        const min = box.min;
        const max = box.max;
        
        // Define the 8 vertices of the bounding box cube
        const boxVertices = [
            new THREE.Vector3(min.x, min.y, min.z), // 0: (0,0,0)
            new THREE.Vector3(max.x, min.y, min.z), // 1: (M,0,0)
            new THREE.Vector3(max.x, max.y, min.z), // 2: (M,M,0)
            new THREE.Vector3(min.x, max.y, min.z), // 3: (0,M,0)
            new THREE.Vector3(min.x, min.y, max.z), // 4: (0,0,M)
            new THREE.Vector3(max.x, min.y, max.z), // 5: (M,0,M)
            new THREE.Vector3(max.x, max.y, max.z), // 6: (M,M,M)
            new THREE.Vector3(min.x, max.y, max.z), // 7: (0,M,M)
        ];

        // Define the 6 faces of the cube (each face as 4 vertices in counter-clockwise order)
        const faces = [
            [0, 1, 2, 3], // Bottom face (z = min.z)
            [4, 7, 6, 5], // Top face (z = max.z)  
            [0, 4, 5, 1], // Front face (y = min.y)
            [2, 6, 7, 3], // Back face (y = max.y)
            [0, 3, 7, 4], // Left face (x = min.x)
            [1, 5, 6, 2], // Right face (x = max.x)
        ];

        // Create wireframe material for bounding box
        const wireframeMaterial = new THREE.LineBasicMaterial({ 
            color: 0x888888,
            transparent: true,
            opacity: 0.3,
            linewidth: 1
        });

        // Create semi-transparent face material for bounding box
        const faceMaterial = new THREE.MeshBasicMaterial({
            color: 0xcccccc,
            transparent: true,
            opacity: 0.1,
            side: THREE.DoubleSide,
            depthWrite: false
        });

        faces.forEach((face, faceIndex) => {
            // Create face geometry
            const faceGeometry = new THREE.BufferGeometry();
            
            // Convert quad to triangles
            const triangles = [
                [boxVertices[face[0]], boxVertices[face[1]], boxVertices[face[2]]], // Triangle 1
                [boxVertices[face[0]], boxVertices[face[2]], boxVertices[face[3]]]  // Triangle 2
            ];
            
            const positions = [];
            triangles.forEach(triangle => {
                triangle.forEach(vertex => {
                    positions.push(vertex.x, vertex.y, vertex.z);
                });
            });
            
            faceGeometry.setAttribute('position', new THREE.Float32BufferAttribute(positions, 3));
            faceGeometry.computeVertexNormals();
            
            // Create face mesh
            const faceMesh = new THREE.Mesh(faceGeometry, faceMaterial);
            faceMesh.name = `bounding-box-face-${faceIndex}`;
            this.scene.add(faceMesh);
            
            // Create wireframe edges for the face
            const edgeGeometry = new THREE.BufferGeometry();
            const edgePositions = [];
            
            // Add edges around the face
            for (let i = 0; i < face.length; i++) {
                const v1 = boxVertices[face[i]];
                const v2 = boxVertices[face[(i + 1) % face.length]];
                edgePositions.push(v1.x, v1.y, v1.z);
                edgePositions.push(v2.x, v2.y, v2.z);
            }
            
            edgeGeometry.setAttribute('position', new THREE.Float32BufferAttribute(edgePositions, 3));
            const edgeMesh = new THREE.LineSegments(edgeGeometry, wireframeMaterial);
            edgeMesh.name = `bounding-box-edges-${faceIndex}`;
            this.scene.add(edgeMesh);
        });
        
        console.log('Added bounding box cube faces');
    }

    animate() {
        requestAnimationFrame(() => this.animate());
        
        this.controls.update();
        this.lipLabels?.update();
        
        this.renderer.render(this.scene, this.camera);
    }

    onWindowResize() {
        if (this.camera && this.renderer) {
            this.camera.aspect = window.innerWidth / window.innerHeight;
            this.camera.updateProjectionMatrix();
            this.renderer.setSize(window.innerWidth, window.innerHeight);
        }
    }

    setupFileUpload() {
        const uploadArea = document.getElementById('upload-area');
        const fileInput = document.getElementById('file-input');
        const sampleDataBtn = document.getElementById('sample-data-btn');
        
        if (!uploadArea || !fileInput || !sampleDataBtn) {
            console.error('Upload elements not found:', { uploadArea, fileInput, sampleDataBtn });
            return;
        }
        
        console.log('Setting up file upload handlers...');
        
        // Click to select file
        uploadArea.addEventListener('click', (event) => {
            event.preventDefault();
            console.log('Upload area clicked, triggering file input...');
            fileInput.click();
        });
        
        // File selection handler
        fileInput.addEventListener('change', (event) => {
            const file = event.target.files[0];
            if (file) {
                this.handleFile(file);
            }
        });
        
        // Drag and drop handlers
        uploadArea.addEventListener('dragover', (event) => {
            event.preventDefault();
            uploadArea.classList.add('dragover');
        });
        
        uploadArea.addEventListener('dragleave', (event) => {
            event.preventDefault();
            uploadArea.classList.remove('dragover');
        });
        
        uploadArea.addEventListener('drop', (event) => {
            event.preventDefault();
            uploadArea.classList.remove('dragover');
            
            const files = event.dataTransfer.files;
            if (files.length > 0) {
                this.handleFile(files[0]);
            }
        });
        
        // Sample data button
        sampleDataBtn.addEventListener('click', (event) => {
            event.preventDefault();
            console.log('Sample data button clicked...');
            this.loadSampleData();
        });
        
        console.log('File upload handlers setup complete');
    }
    
    async handleFile(file) {
        try {
            // Validate file type
            if (!file.name.toLowerCase().endsWith('.json')) {
                throw new Error('Please select a JSON file');
            }
            
            // Show processing indicator
            this.showProcessingIndicator('Processing LIP data...');
            
            // Read file content
            const text = await this.readFileAsText(file);
            
            // Parse JSON
            let data;
            try {
                data = JSON.parse(text);
            } catch (parseError) {
                throw new Error('Invalid JSON format: ' + parseError.message);
            }
            
            // Validate LIP data structure
            this.validateLIPData(data);
            
            // Initialize visualization with the loaded data
            await this.initWithData(data);
            
        } catch (error) {
            console.error('Error handling file:', error);
            this.showError('Failed to load file: ' + error.message);
        } finally {
            this.hideProcessingIndicator();
        }
    }
    
    async loadSampleData() {
        try {
            this.showProcessingIndicator('Loading sample data...');
            
            const response = await fetch('./data/LIP.json');
            if (!response.ok) {
                throw new Error(`HTTP ${response.status}: ${response.statusText}`);
            }
            
            const data = await response.json();
            this.validateLIPData(data);
            
            await this.initWithData(data);
            
        } catch (error) {
            console.error('Error loading sample data:', error);
            this.showError('Failed to load sample data: ' + error.message);
        } finally {
            this.hideProcessingIndicator();
        }
    }
    
    readFileAsText(file) {
        return new Promise((resolve, reject) => {
            const reader = new FileReader();
            reader.onload = (event) => resolve(event.target.result);
            reader.onerror = (error) => reject(error);
            reader.readAsText(file);
        });
    }
    
    validateLIPData(data) {
        const requiredFields = ['vertices', 'facets', 'labels', 'bundles'];
        
        for (const field of requiredFields) {
            if (!data[field]) {
                throw new Error(`Missing required field: ${field}`);
            }
            if (!Array.isArray(data[field])) {
                throw new Error(`Field ${field} must be an array`);
            }
        }
        
        // Basic validation
        if (data.vertices.length === 0) {
            throw new Error('No vertices found in LIP data');
        }
        
        if (data.facets.length === 0) {
            throw new Error('No facets found in LIP data');
        }
        
        // Validate vertex format
        for (let i = 0; i < Math.min(5, data.vertices.length); i++) {
            const vertex = data.vertices[i];
            if (!Array.isArray(vertex) || vertex.length !== 3) {
                throw new Error(`Invalid vertex format at index ${i} - expected [x, y, z]`);
            }
        }
        
        console.log('LIP data validation passed:', {
            vertices: data.vertices.length,
            facets: data.facets.length,
            labels: data.labels.length,
            bundles: data.bundles.length
        });
    }
    
    showProcessingIndicator(message) {
        let indicator = document.getElementById('processing-indicator');
        if (!indicator) {
            indicator = document.createElement('div');
            indicator.id = 'processing-indicator';
            indicator.className = 'processing-indicator';
            indicator.innerHTML = `
                <div class="spinner"></div>
                <div class="processing-text">${message}</div>
            `;
            document.body.appendChild(indicator);
        }
        indicator.style.display = 'block';
        indicator.querySelector('.processing-text').textContent = message;
    }
    
    hideProcessingIndicator() {
        const indicator = document.getElementById('processing-indicator');
        if (indicator) {
            indicator.style.display = 'none';
        }
    }

    showError(message) {
        console.error('LIP Visualization Error:', message);
        
        // The new interface handles errors via events, not direct DOM manipulation
        window.dispatchEvent(new CustomEvent('lipVisualizationError', {
            detail: { message }
        }));
    }
}

// Initialize the visualization when the page loads
window.addEventListener('DOMContentLoaded', () => {
    console.log('DOM Content Loaded, initializing LIP visualization...');
    
    try {
        const visualization = new LIPVisualization();
        window.lipVisualization = visualization; // Make it accessible for debugging
        visualization.init();
        
        // Handle window resize
        window.addEventListener('resize', () => {
            visualization.onWindowResize();
        });
        
        console.log('Visualization setup complete');
    } catch (error) {
        console.error('Error during initialization:', error);
        
        // Show error on page
        const errorDiv = document.createElement('div');
        errorDiv.style.cssText = `
            position: fixed;
            top: 20px;
            right: 20px;
            background: #ff4444;
            color: white;
            padding: 15px;
            border-radius: 5px;
            z-index: 10000;
            max-width: 400px;
        `;
        errorDiv.textContent = 'JavaScript Error: ' + error.message;
        document.body.appendChild(errorDiv);
    }
});
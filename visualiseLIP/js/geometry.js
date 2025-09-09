/**
 * LIPGeometry - Handles loading and constructing geometry from LIP.json
 * Converts facet data into Three.js geometries
 */

import * as THREE from 'three';

export class LIPGeometry {
    constructor(data) {
        this.data = data;
        this.vertices = this.parseVertices();
        this.facets = this.parseFacets();
    }

    parseVertices() {
        if (!this.data.vertices) {
            throw new Error('No vertices found in LIP data');
        }
        
        return this.data.vertices.map(vertex => {
            if (!Array.isArray(vertex) || vertex.length !== 3) {
                throw new Error('Invalid vertex format - expected [x, y, z]');
            }
            return new THREE.Vector3(vertex[0], vertex[1], vertex[2]);
        });
    }

    parseFacets() {
        if (!this.data.facets) {
            throw new Error('No facets found in LIP data');
        }
        
        return this.data.facets.map(facet => {
            if (!Array.isArray(facet)) {
                throw new Error('Invalid facet format - expected array of vertex indices');
            }
            
            // Validate indices
            const validIndices = facet.filter(index => 
                Number.isInteger(index) && index >= 0 && index < this.vertices.length
            );
            
            if (validIndices.length < 3) {
                console.warn(`Skipping facet with insufficient vertices: ${facet}`);
                return null;
            }
            
            return validIndices;
        }).filter(facet => facet !== null);
    }

    createFacetGeometries() {
        const geometries = [];
        
        console.log('=== DEBUG: Processing facets ===');
        console.log(`Total facets: ${this.facets.length}`);
        console.log(`Total vertices: ${this.vertices.length}`);
        
        // Show first few vertices to verify data loading
        console.log('First 5 vertices:');
        for (let i = 0; i < Math.min(5, this.vertices.length); i++) {
            const v = this.vertices[i];
            console.log(`  V${i}: (${v.x}, ${v.y}, ${v.z})`);
        }
        
        // Analyze facet dimensions
        const facetsBySize = {};
        this.facets.forEach((facetIndices, index) => {
            const size = facetIndices.length;
            if (!facetsBySize[size]) facetsBySize[size] = [];
            facetsBySize[size].push(index);
        });
        
        console.log('Facets by vertex count:');
        Object.keys(facetsBySize).forEach(size => {
            console.log(`  ${size} vertices: ${facetsBySize[size].length} facets`);
        });
        
        this.facets.forEach((facetIndices, index) => {
            try {
                const facetVertices = facetIndices.map(i => this.vertices[i]);
                
                // DEBUG: Only show the FIRST four-vertex facet to debug triangulation
                if (facetVertices.length === 4 && index > 0) {
                    console.log(`Skipping facet ${index} (showing only FIRST four-vertex facet for debugging)`);
                    return;
                }
                
                // Debug the first few 4-vertex facets (these should be our main planes)
                if (facetVertices.length === 4 && index < 5) {
                    console.log(`\nDEBUG Facet ${index} (4 vertices):`);
                    console.log('  Indices:', facetIndices);
                    console.log('  Vertices:');
                    facetVertices.forEach((v, i) => {
                        console.log(`    V${i}: (${v.x.toFixed(3)}, ${v.y.toFixed(3)}, ${v.z.toFixed(3)})`);
                    });
                    
                    // Check if this is one of our expected planes (p₁=1, p₂=1, or p₃=1)
                    const coords = facetVertices.map(v => [v.x, v.y, v.z]);
                    const x_coords = coords.map(c => c[0]);
                    const y_coords = coords.map(c => c[1]); 
                    const z_coords = coords.map(c => c[2]);
                    
                    const x_const = Math.abs(Math.max(...x_coords) - Math.min(...x_coords)) < 0.001;
                    const y_const = Math.abs(Math.max(...y_coords) - Math.min(...y_coords)) < 0.001;
                    const z_const = Math.abs(Math.max(...z_coords) - Math.min(...z_coords)) < 0.001;
                    
                    if (x_const && Math.abs(x_coords[0] - 1) < 0.001) {
                        console.log('  → This is the p₁ = 1 plane! ✓');
                    } else if (y_const && Math.abs(y_coords[0] - 1) < 0.001) {
                        console.log('  → This is the p₂ = 1 plane! ✓');
                    } else if (z_const && Math.abs(z_coords[0] - 1) < 0.001) {
                        console.log('  → This is the p₃ = 1 plane! ✓');
                    } else {
                        console.log('  → Not a simple coordinate plane');
                        console.log(`    X range: [${Math.min(...x_coords).toFixed(3)}, ${Math.max(...x_coords).toFixed(3)}]`);
                        console.log(`    Y range: [${Math.min(...y_coords).toFixed(3)}, ${Math.max(...y_coords).toFixed(3)}]`);
                        console.log(`    Z range: [${Math.min(...z_coords).toFixed(3)}, ${Math.max(...z_coords).toFixed(3)}]`);
                    }
                }
                
                // Render 4-vertex facets as simple wireframes (avoid triangulation issues)
                if (facetVertices.length === 4) {
                    console.log(`Creating wireframe for facet ${index} with 4 vertices`);
                    
                    // Create simple wireframe geometry - just the edges of the rectangle
                    const wireframeGeometry = this.createWireframeQuad(facetVertices);
                    
                    if (wireframeGeometry) {
                        geometries.push({
                            geometry: wireframeGeometry,
                            vertices: facetVertices,
                            indices: facetIndices,
                            id: index,
                            dimension: 2,
                            isWireframe: true
                        });
                        
                        console.log(`✓ Added wireframe facet ${index}`);
                    }
                }
            } catch (error) {
                console.warn(`Failed to create geometry for facet ${index}:`, error);
            }
        });
        
        console.log(`\nCreated ${geometries.length} face geometries (${this.facets.length} total facets)`);
        return geometries;
    }

    createFacetGeometry(vertices, facetId) {
        if (vertices.length < 3) {
            return null;
        }
        
        // For 3 vertices, create a triangle
        if (vertices.length === 3) {
            return this.createTriangleGeometry(vertices);
        }
        
        // For 4+ vertices, triangulate the polygon
        return this.createPolygonGeometry(vertices, facetId);
    }

    createTriangleGeometry(vertices) {
        const geometry = new THREE.BufferGeometry();
        const positions = new Float32Array(9); // 3 vertices * 3 coordinates
        const normals = new Float32Array(9);
        
        // Set positions
        for (let i = 0; i < 3; i++) {
            positions[i * 3] = vertices[i].x;
            positions[i * 3 + 1] = vertices[i].y;
            positions[i * 3 + 2] = vertices[i].z;
        }
        
        // Calculate normal
        const normal = this.calculateNormal(vertices[0], vertices[1], vertices[2]);
        for (let i = 0; i < 3; i++) {
            normals[i * 3] = normal.x;
            normals[i * 3 + 1] = normal.y;
            normals[i * 3 + 2] = normal.z;
        }
        
        geometry.setAttribute('position', new THREE.BufferAttribute(positions, 3));
        geometry.setAttribute('normal', new THREE.BufferAttribute(normals, 3));
        
        return geometry;
    }

    createPolygonGeometry(vertices, facetId) {
        try {
            // Simple direct approach - just create the geometry from triangulated vertices
            const triangles = this.triangulatePolygon(vertices);
            
            if (triangles.length === 0) {
                console.warn(`Failed to triangulate facet ${facetId}`);
                return null;
            }
            
            const positions = [];
            const normals = [];
            
            // Calculate polygon normal (assuming coplanar vertices)
            const polygonNormal = this.calculatePolygonNormal(vertices);
            
            triangles.forEach(triangle => {
                triangle.forEach(vertex => {
                    positions.push(vertex.x, vertex.y, vertex.z);
                    normals.push(polygonNormal.x, polygonNormal.y, polygonNormal.z);
                });
            });
            
            const geometry = new THREE.BufferGeometry();
            geometry.setAttribute('position', new THREE.Float32BufferAttribute(positions, 3));
            geometry.setAttribute('normal', new THREE.Float32BufferAttribute(normals, 3));
            
            console.log(`Created geometry with ${positions.length/3} vertices from ${triangles.length} triangles`);
            
            return geometry;
        } catch (error) {
            console.warn(`Failed to create polygon geometry for facet ${facetId}:`, error);
            return null;
        }
    }

    createShapeGeometryFromPolygon(vertices) {
        // Generic solution using Three.js Shape and ShapeGeometry
        // Works for any number of vertices
        
        console.log(`Creating ShapeGeometry for ${vertices.length} vertices`);
        
        // Calculate polygon normal to determine best projection plane
        const normal = this.calculatePolygonNormal(vertices);
        
        // Project vertices to 2D plane
        const projected2D = this.projectVerticesTo2D(vertices, normal);
        
        console.log('Projected 2D coordinates:');
        projected2D.forEach((p, i) => {
            console.log(`  P${i}: (${p.x.toFixed(3)}, ${p.y.toFixed(3)})`);
        });
        
        // Create Three.js Shape from 2D points
        const shape = new THREE.Shape();
        shape.moveTo(projected2D[0].x, projected2D[0].y);
        for (let i = 1; i < projected2D.length; i++) {
            shape.lineTo(projected2D[i].x, projected2D[i].y);
        }
        shape.lineTo(projected2D[0].x, projected2D[0].y); // Close the shape
        
        // Create geometry from shape (this handles triangulation automatically)
        const shapeGeometry = new THREE.ShapeGeometry(shape);
        
        // Transform back to 3D space
        this.transformGeometryTo3D(shapeGeometry, vertices, normal, projected2D);
        
        console.log(`✓ Created ShapeGeometry with ${shapeGeometry.attributes.position.count} vertices`);
        return shapeGeometry;
    }

    projectVerticesTo2D(vertices, normal) {
        // Choose the best 2D projection plane based on normal vector
        const absNormal = new THREE.Vector3(Math.abs(normal.x), Math.abs(normal.y), Math.abs(normal.z));
        
        let projectedPoints;
        
        if (absNormal.z >= absNormal.x && absNormal.z >= absNormal.y) {
            // Project to XY plane (ignore Z)
            projectedPoints = vertices.map(v => ({ x: v.x, y: v.y }));
            console.log('Projecting to XY plane');
        } else if (absNormal.y >= absNormal.x && absNormal.y >= absNormal.z) {
            // Project to XZ plane (ignore Y)
            projectedPoints = vertices.map(v => ({ x: v.x, y: v.z }));
            console.log('Projecting to XZ plane');
        } else {
            // Project to YZ plane (ignore X)
            projectedPoints = vertices.map(v => ({ x: v.y, y: v.z }));
            console.log('Projecting to YZ plane');
        }
        
        return projectedPoints;
    }

    transformGeometryTo3D(geometry, originalVertices, normal, projected2D) {
        // Transform the 2D ShapeGeometry back to the original 3D plane
        const positions = geometry.attributes.position.array;
        
        // Create transformation matrix from 2D plane to 3D space
        // This is a simplified approach - we'll map the 2D triangulated points
        // back to the 3D plane using barycentric coordinates
        
        for (let i = 0; i < positions.length; i += 3) {
            const x2d = positions[i];
            const y2d = positions[i + 1];
            
            // Find the corresponding 3D point using simple interpolation
            // For now, we'll use the projection plane approach
            if (Math.abs(normal.z) >= Math.abs(normal.x) && Math.abs(normal.z) >= Math.abs(normal.y)) {
                // Was XY projection, restore Z using plane equation
                positions[i] = x2d;     // X stays the same
                positions[i + 1] = y2d; // Y stays the same
                positions[i + 2] = this.interpolateZ(x2d, y2d, originalVertices); // Interpolate Z
            } else if (Math.abs(normal.y) >= Math.abs(normal.x) && Math.abs(normal.y) >= Math.abs(normal.z)) {
                // Was XZ projection, restore Y
                positions[i] = x2d;     // X stays the same
                positions[i + 1] = this.interpolateY(x2d, y2d, originalVertices); // Interpolate Y
                positions[i + 2] = y2d; // Z (was Y in 2D)
            } else {
                // Was YZ projection, restore X
                positions[i] = this.interpolateX(x2d, y2d, originalVertices);     // Interpolate X
                positions[i + 1] = x2d; // Y (was X in 2D)
                positions[i + 2] = y2d; // Z (was Y in 2D)
            }
        }
        
        // Recalculate normals
        geometry.computeVertexNormals();
    }

    interpolateZ(x, y, vertices) {
        // Simple approach: find the Z value on the plane defined by the vertices
        // For axis-aligned planes, this should be constant
        const zValues = vertices.map(v => v.z);
        const avgZ = zValues.reduce((sum, z) => sum + z, 0) / zValues.length;
        return avgZ;
    }

    interpolateY(x, z, vertices) {
        const yValues = vertices.map(v => v.y);
        const avgY = yValues.reduce((sum, y) => sum + y, 0) / yValues.length;
        return avgY;
    }

    interpolateX(y, z, vertices) {
        const xValues = vertices.map(v => v.x);
        const avgX = xValues.reduce((sum, x) => sum + x, 0) / xValues.length;
        return avgX;
    }

    triangulatePolygon(vertices) {
        console.log(`Triangulating ${vertices.length}-vertex polygon:`);
        vertices.forEach((v, i) => {
            console.log(`  V${i}: (${v.x.toFixed(3)}, ${v.y.toFixed(3)}, ${v.z.toFixed(3)})`);
        });
        
        if (vertices.length === 3) {
            console.log('Already a triangle');
            return [vertices];
        }
        
        if (vertices.length === 4) {
            // For 4 vertices, use a simple but reliable approach
            console.log('Using simple quad triangulation');
            return [
                [vertices[0], vertices[1], vertices[2]],
                [vertices[0], vertices[2], vertices[3]]
            ];
        }
        
        // For 5+ vertices, use fan triangulation from first vertex
        console.log(`Using fan triangulation for ${vertices.length} vertices`);
        const triangles = [];
        for (let i = 1; i < vertices.length - 1; i++) {
            triangles.push([vertices[0], vertices[i], vertices[i + 1]]);
            console.log(`Triangle: V0-V${i}-V${i+1}`);
        }
        
        console.log(`Created ${triangles.length} triangles`);
        return triangles;
    }

    createWireframeQuad(vertices) {
        // Create a simple wireframe for a 4-vertex polygon
        // Just draw the edges - no triangulation needed!
        
        if (vertices.length !== 4) {
            return null;
        }
        
        const positions = [];
        
        // Create lines for each edge of the quad
        // Edge 0-1
        positions.push(vertices[0].x, vertices[0].y, vertices[0].z);
        positions.push(vertices[1].x, vertices[1].y, vertices[1].z);
        
        // Edge 1-2  
        positions.push(vertices[1].x, vertices[1].y, vertices[1].z);
        positions.push(vertices[2].x, vertices[2].y, vertices[2].z);
        
        // Edge 2-3
        positions.push(vertices[2].x, vertices[2].y, vertices[2].z);
        positions.push(vertices[3].x, vertices[3].y, vertices[3].z);
        
        // Edge 3-0 (close the quad)
        positions.push(vertices[3].x, vertices[3].y, vertices[3].z);
        positions.push(vertices[0].x, vertices[0].y, vertices[0].z);
        
        const geometry = new THREE.BufferGeometry();
        geometry.setAttribute('position', new THREE.Float32BufferAttribute(positions, 3));
        
        console.log(`Created wireframe quad with ${positions.length/3} line vertices`);
        return geometry;
    }

    calculateNormal(v1, v2, v3) {
        const edge1 = new THREE.Vector3().subVectors(v2, v1);
        const edge2 = new THREE.Vector3().subVectors(v3, v1);
        const normal = new THREE.Vector3().crossVectors(edge1, edge2);
        return normal.normalize();
    }

    calculatePolygonNormal(vertices) {
        if (vertices.length < 3) {
            return new THREE.Vector3(0, 1, 0); // Default up vector
        }
        
        // Use Newell's method for robust normal calculation
        const normal = new THREE.Vector3(0, 0, 0);
        
        for (let i = 0; i < vertices.length; i++) {
            const v1 = vertices[i];
            const v2 = vertices[(i + 1) % vertices.length];
            
            normal.x += (v1.y - v2.y) * (v1.z + v2.z);
            normal.y += (v1.z - v2.z) * (v1.x + v2.x);
            normal.z += (v1.x - v2.x) * (v1.y + v2.y);
        }
        
        return normal.normalize();
    }

    orderRectangleVertices(vertices) {
        if (vertices.length !== 4) {
            return vertices; // Not a quad, return as-is
        }
        
        // For a plane perpendicular to one axis (like p₁=1, p₂=1, p₃=1),
        // we need to sort vertices to form a proper rectangle cycle
        
        // Find which coordinate is constant (determines the plane)
        const coords = vertices.map(v => [v.x, v.y, v.z]);
        const x_values = coords.map(c => c[0]);
        const y_values = coords.map(c => c[1]);
        const z_values = coords.map(c => c[2]);
        
        const x_const = Math.abs(Math.max(...x_values) - Math.min(...x_values)) < 0.001;
        const y_const = Math.abs(Math.max(...y_values) - Math.min(...y_values)) < 0.001;
        const z_const = Math.abs(Math.max(...z_values) - Math.min(...z_values)) < 0.001;
        
        if (x_const) {
            // x is constant, sort by y then z to get proper rectangle order
            return vertices.sort((a, b) => {
                if (Math.abs(a.y - b.y) < 0.001) {
                    return a.z - b.z; // Same y, sort by z
                }
                return a.y - b.y; // Sort by y first
            });
        } else if (y_const) {
            // y is constant, sort by x then z
            return vertices.sort((a, b) => {
                if (Math.abs(a.x - b.x) < 0.001) {
                    return a.z - b.z; // Same x, sort by z
                }
                return a.x - b.x; // Sort by x first
            });
        } else if (z_const) {
            // z is constant, sort by x then y
            return vertices.sort((a, b) => {
                if (Math.abs(a.x - b.x) < 0.001) {
                    return a.y - b.y; // Same x, sort by y
                }
                return a.x - b.x; // Sort by x first
            });
        }
        
        // Not a simple axis-aligned plane, return as-is for now
        console.warn('Complex polygon - using original vertex order');
        return vertices;
    }

    triangulateQuadSimple(vertices) {
        // Simple approach: for 4 vertices, there are only 2 possible triangulations
        // Try both and pick the one that creates more reasonable triangles
        
        const [v0, v1, v2, v3] = vertices;
        
        // Option 1: Split along diagonal 0-2
        const option1 = [
            [v0, v1, v2],
            [v0, v2, v3]
        ];
        
        // Option 2: Split along diagonal 1-3  
        const option2 = [
            [v0, v1, v3],
            [v1, v2, v3]
        ];
        
        // Calculate areas to see which split makes more sense
        const area1 = this.getTriangleArea(v0, v1, v2) + this.getTriangleArea(v0, v2, v3);
        const area2 = this.getTriangleArea(v0, v1, v3) + this.getTriangleArea(v1, v2, v3);
        
        console.log(`Option 1 (diagonal 0-2) total area: ${area1.toFixed(4)}`);
        console.log(`Option 2 (diagonal 1-3) total area: ${area2.toFixed(4)}`);
        
        // Choose the option with larger total area (more likely to be correct)
        const chosen = area1 >= area2 ? option1 : option2;
        const diag = area1 >= area2 ? "0-2" : "1-3";
        
        console.log(`Chose diagonal ${diag} triangulation`);
        return chosen;
    }
    
    getTriangleArea(v1, v2, v3) {
        // Calculate triangle area using cross product
        const edge1 = new THREE.Vector3().subVectors(v2, v1);
        const edge2 = new THREE.Vector3().subVectors(v3, v1);
        const cross = new THREE.Vector3().crossVectors(edge1, edge2);
        return cross.length() / 2;
    }

    createFacetMesh(geometryData, material) {
        if (!geometryData.geometry) {
            return null;
        }
        
        let mesh;
        
        if (geometryData.isWireframe) {
            // Create LineSegments for wireframes
            const lineMaterial = new THREE.LineBasicMaterial({ 
                color: 0x0077ff,
                linewidth: 2
            });
            mesh = new THREE.LineSegments(geometryData.geometry, lineMaterial);
            console.log('Created LineSegments for wireframe facet');
        } else {
            // Create regular mesh for solid faces
            mesh = new THREE.Mesh(geometryData.geometry, material);
            console.log('Created Mesh for solid facet');
        }
        
        // Store metadata for interaction
        mesh.userData = {
            facetId: geometryData.id,
            vertexIndices: geometryData.indices,
            vertexCount: geometryData.vertices.length
        };
        
        return mesh;
    }

    createVertexGeometry() {
        const positions = [];
        
        this.vertices.forEach(vertex => {
            positions.push(vertex.x, vertex.y, vertex.z);
        });
        
        const geometry = new THREE.BufferGeometry();
        geometry.setAttribute('position', new THREE.Float32BufferAttribute(positions, 3));
        
        return geometry;
    }

    createWireframeGeometry() {
        const positions = [];
        
        // Only create wireframes for 2D facets (faces)
        this.facets.forEach(facetIndices => {
            if (facetIndices.length >= 3) {
                // Create lines for each edge of the facet
                for (let i = 0; i < facetIndices.length; i++) {
                    const v1 = this.vertices[facetIndices[i]];
                    const v2 = this.vertices[facetIndices[(i + 1) % facetIndices.length]];
                    
                    positions.push(v1.x, v1.y, v1.z);
                    positions.push(v2.x, v2.y, v2.z);
                }
            }
        });
        
        const geometry = new THREE.BufferGeometry();
        geometry.setAttribute('position', new THREE.Float32BufferAttribute(positions, 3));
        
        return geometry;
    }

    createEdgeGeometry() {
        const positions = [];
        
        // Create lines for 1D facets (edges)
        this.facets.forEach(facetIndices => {
            if (facetIndices.length === 2) {
                const v1 = this.vertices[facetIndices[0]];
                const v2 = this.vertices[facetIndices[1]];
                
                positions.push(v1.x, v1.y, v1.z);
                positions.push(v2.x, v2.y, v2.z);
            }
        });
        
        const geometry = new THREE.BufferGeometry();
        geometry.setAttribute('position', new THREE.Float32BufferAttribute(positions, 3));
        
        return geometry;
    }

    getBoundingBox() {
        if (this.vertices.length === 0) {
            return new THREE.Box3();
        }
        
        const box = new THREE.Box3();
        this.vertices.forEach(vertex => {
            box.expandByPoint(vertex);
        });
        
        return box;
    }

    getCenter() {
        const box = this.getBoundingBox();
        return box.getCenter(new THREE.Vector3());
    }

    getSize() {
        const box = this.getBoundingBox();
        return box.getSize(new THREE.Vector3());
    }

    // Utility method to validate the loaded data
    validate() {
        const errors = [];
        
        if (!this.vertices || this.vertices.length === 0) {
            errors.push('No vertices found');
        }
        
        if (!this.facets || this.facets.length === 0) {
            errors.push('No facets found');
        }
        
        // Check for invalid facet indices
        this.facets.forEach((facet, index) => {
            const invalidIndices = facet.filter(i => i < 0 || i >= this.vertices.length);
            if (invalidIndices.length > 0) {
                errors.push(`Facet ${index} has invalid vertex indices: ${invalidIndices}`);
            }
        });
        
        return {
            isValid: errors.length === 0,
            errors
        };
    }
}
/**
 * LIPMaterials - Handles material creation and management for LIP visualization
 * Provides different materials for facets, vertices, and wireframes
 */

import * as THREE from 'three';

export class LIPMaterials {
    constructor() {
        this.facetMaterials = [];
        this.vertexMaterial = null;
        this.wireframeMaterial = null;
        this.transparency = 0.7;
        this.wireframeEnabled = false;
        
        // Color palette for different facets
        this.colorPalette = [
            0xff6b6b, 0x4ecdc4, 0x45b7d1, 0xf9ca24,
            0xf0932b, 0xeb4d4b, 0x6c5ce7, 0xa29bfe,
            0xfd79a8, 0xe17055, 0x00b894, 0x00cec9,
            0x55a3ff, 0x6c5ce7, 0xa29bfe, 0xffeaa7,
            0xdda0dd, 0x98fb98, 0x87ceeb, 0xf0e68c,
            0xff7f50, 0x20b2aa, 0x9370db, 0x3cb371,
            0xff69b4, 0x1e90ff, 0x32cd32, 0xffd700,
        ];
    }

    createFacetMaterials(count) {
        this.facetMaterials = [];
        
        for (let i = 0; i < count; i++) {
            const color = this.colorPalette[i % this.colorPalette.length];
            
            const material = new THREE.MeshLambertMaterial({
                color: color,
                transparent: true,
                opacity: this.transparency,
                side: THREE.DoubleSide, // Render both sides of faces
                wireframe: this.wireframeEnabled,
                depthWrite: false, // Prevent Z-fighting with transparent materials
            });
            
            // Store original properties for later modification
            material.userData = {
                originalColor: color,
                originalOpacity: this.transparency,
                facetIndex: i
            };
            
            this.facetMaterials.push(material);
        }
        
        return this.facetMaterials;
    }

    createVertexMaterial() {
        this.vertexMaterial = new THREE.PointsMaterial({
            color: 0x333333,
            size: 0.1,
            sizeAttenuation: true,
            transparent: true,
            opacity: 0.8
        });
        
        return this.vertexMaterial;
    }

    createWireframeMaterial() {
        this.wireframeMaterial = new THREE.LineBasicMaterial({
            color: 0x000000,
            transparent: true,
            opacity: 0.3,
            linewidth: 1
        });
        
        return this.wireframeMaterial;
    }

    createHighlightMaterial() {
        return new THREE.MeshLambertMaterial({
            color: 0xffff00,
            transparent: true,
            opacity: 0.9,
            side: THREE.DoubleSide,
            emissive: 0x444400,
            depthWrite: false
        });
    }

    createBoundingBoxMaterial() {
        return new THREE.LineBasicMaterial({
            color: 0x999999,
            transparent: true,
            opacity: 0.3,
            linewidth: 1
        });
    }

    updateTransparency(value) {
        this.transparency = Math.max(0.1, Math.min(1.0, value));
        
        this.facetMaterials.forEach(material => {
            material.opacity = this.transparency;
            material.needsUpdate = true;
        });
    }

    toggleWireframe(enabled) {
        this.wireframeEnabled = enabled;
        
        this.facetMaterials.forEach(material => {
            material.wireframe = enabled;
            material.needsUpdate = true;
        });
    }

    highlightFacet(facetIndex, highlight = true) {
        if (facetIndex >= 0 && facetIndex < this.facetMaterials.length) {
            const material = this.facetMaterials[facetIndex];
            
            if (highlight) {
                material.emissive = new THREE.Color(0x444444);
                material.opacity = Math.min(1.0, this.transparency + 0.3);
            } else {
                material.emissive = new THREE.Color(0x000000);
                material.opacity = this.transparency;
            }
            
            material.needsUpdate = true;
        }
    }

    setFacetColor(facetIndex, color) {
        if (facetIndex >= 0 && facetIndex < this.facetMaterials.length) {
            const material = this.facetMaterials[facetIndex];
            material.color = new THREE.Color(color);
            material.needsUpdate = true;
        }
    }

    resetFacetColor(facetIndex) {
        if (facetIndex >= 0 && facetIndex < this.facetMaterials.length) {
            const material = this.facetMaterials[facetIndex];
            const originalColor = material.userData.originalColor;
            material.color = new THREE.Color(originalColor);
            material.needsUpdate = true;
        }
    }

    resetAllColors() {
        this.facetMaterials.forEach((material, index) => {
            this.resetFacetColor(index);
        });
    }

    setVisibility(facetIndex, visible) {
        if (facetIndex >= 0 && facetIndex < this.facetMaterials.length) {
            const material = this.facetMaterials[facetIndex];
            material.visible = visible;
            material.needsUpdate = true;
        }
    }

    setAllVisibility(visible) {
        this.facetMaterials.forEach(material => {
            material.visible = visible;
            material.needsUpdate = true;
        });
    }

    // Method to create materials based on bundle types
    createBundleMaterials(bundles) {
        const bundleMaterials = {};
        
        bundles.forEach((bundle, index) => {
            const color = this.colorPalette[index % this.colorPalette.length];
            
            bundleMaterials[bundle] = new THREE.MeshLambertMaterial({
                color: color,
                transparent: true,
                opacity: this.transparency,
                side: THREE.DoubleSide,
                wireframe: this.wireframeEnabled,
                depthWrite: false
            });
            
            bundleMaterials[bundle].userData = {
                originalColor: color,
                bundleName: bundle,
                bundleIndex: index
            };
        });
        
        return bundleMaterials;
    }

    // Utility method to generate distinct colors
    generateDistinctColor(index, total) {
        const hue = (index * 360 / total) % 360;
        const saturation = 70 + (index * 15) % 30; // 70-100%
        const lightness = 50 + (index * 10) % 25;  // 50-75%
        
        return `hsl(${hue}, ${saturation}%, ${lightness}%)`;
    }

    // Create a gradient material for special effects
    createGradientMaterial(color1, color2) {
        // This would require a custom shader material for true gradients
        // For now, we'll create a simple two-tone material
        const avgColor = new THREE.Color(color1).lerp(new THREE.Color(color2), 0.5);
        
        return new THREE.MeshLambertMaterial({
            color: avgColor,
            transparent: true,
            opacity: this.transparency,
            side: THREE.DoubleSide,
            depthWrite: false
        });
    }

    // Dispose of materials to free memory
    dispose() {
        this.facetMaterials.forEach(material => {
            material.dispose();
        });
        
        if (this.vertexMaterial) this.vertexMaterial.dispose();
        if (this.wireframeMaterial) this.wireframeMaterial.dispose();
        
        this.facetMaterials = [];
        this.vertexMaterial = null;
        this.wireframeMaterial = null;
    }
}
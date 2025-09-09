/**
 * LIPLabels - Handles bundle labeling and text management for LIP visualization
 * Creates and manages Three.js sprite-based text labels at bundle centers
 */

import * as THREE from 'three';

export class LIPLabels {
    constructor(data, camera, renderer) {
        this.data = data;
        this.camera = camera;
        this.renderer = renderer;
        this.labels = [];
        this.sprites = [];
        this.visible = true;
        this.labelGroup = new THREE.Group();
        this.labelGroup.name = 'LIP-Labels';
        
        // Label styling
        this.fontSize = 48;
        this.fontFamily = 'Arial, sans-serif';
        this.backgroundColor = 'rgba(255, 255, 255, 0.9)';
        this.textColor = '#333';
        this.borderColor = '#ccc';
        this.padding = 8;
    }

    createTextCanvas(text, fontSize = this.fontSize) {
        const canvas = document.createElement('canvas');
        const context = canvas.getContext('2d');
        
        // Set font
        context.font = `bold ${fontSize}px ${this.fontFamily}`;
        
        // Measure text
        const metrics = context.measureText(text);
        const textWidth = metrics.width;
        const textHeight = fontSize;
        
        // Add padding
        const canvasWidth = textWidth + (this.padding * 2);
        const canvasHeight = textHeight + (this.padding * 2);
        
        // Set canvas size
        canvas.width = canvasWidth;
        canvas.height = canvasHeight;
        
        // Set font again after canvas resize
        context.font = `bold ${fontSize}px ${this.fontFamily}`;
        context.textAlign = 'center';
        context.textBaseline = 'middle';
        
        // Draw background
        context.fillStyle = this.backgroundColor;
        context.strokeStyle = this.borderColor;
        context.lineWidth = 2;
        
        const radius = 6;
        const x = 0;
        const y = 0;
        const width = canvasWidth;
        const height = canvasHeight;
        
        // Draw rounded rectangle background
        context.beginPath();
        context.moveTo(x + radius, y);
        context.lineTo(x + width - radius, y);
        context.quadraticCurveTo(x + width, y, x + width, y + radius);
        context.lineTo(x + width, y + height - radius);
        context.quadraticCurveTo(x + width, y + height, x + width - radius, y + height);
        context.lineTo(x + radius, y + height);
        context.quadraticCurveTo(x, y + height, x, y + height - radius);
        context.lineTo(x, y + radius);
        context.quadraticCurveTo(x, y, x + radius, y);
        context.closePath();
        
        context.fill();
        context.stroke();
        
        // Draw text
        context.fillStyle = this.textColor;
        context.fillText(text, canvasWidth / 2, canvasHeight / 2);
        
        return canvas;
    }

    createLabels() {
        if (!this.data.labels || !this.data.bundles) {
            console.warn('No labels or bundles data found');
            return;
        }
        
        // Clear existing labels
        this.labelGroup.clear();
        this.sprites = [];
        this.labels = [];
        
        this.data.labels.forEach((position, index) => {
            if (index < this.data.bundles.length) {
                const sprite = this.createLabelSprite(
                    position,
                    this.data.bundles[index],
                    index
                );
                if (sprite) {
                    this.sprites.push(sprite);
                    this.labelGroup.add(sprite);
                    
                    // Store label data for reference
                    this.labels.push({
                        sprite: sprite,
                        position3D: new THREE.Vector3(position[0], position[1], position[2]),
                        bundleName: this.data.bundles[index],
                        index: index,
                        visible: true
                    });
                }
            }
        });
        
        console.log(`Created ${this.sprites.length} label sprites`);
    }

    createLabelSprite(position, bundleName, index) {
        const formattedName = this.formatBundleName(bundleName);
        
        // Create canvas texture from text
        const canvas = this.createTextCanvas(formattedName);
        const texture = new THREE.CanvasTexture(canvas);
        texture.needsUpdate = true;
        
        // Create sprite material
        const material = new THREE.SpriteMaterial({
            map: texture,
            transparent: true,
            depthTest: false,
            depthWrite: false
        });
        
        // Create sprite
        const sprite = new THREE.Sprite(material);
        
        // Position the sprite
        sprite.position.set(position[0], position[1], position[2]);
        
        // Scale sprite based on canvas size and desired world size
        const scale = 0.5; // Adjust this to make labels larger or smaller
        sprite.scale.set(
            (canvas.width / this.fontSize) * scale,
            (canvas.height / this.fontSize) * scale,
            1
        );
        
        // Store metadata
        sprite.userData = {
            bundleName: bundleName,
            formattedName: formattedName,
            index: index,
            originalScale: sprite.scale.clone()
        };
        
        // Make sprite always face camera
        sprite.material.rotation = 0;
        
        return sprite;
    }

    formatBundleName(bundleName) {
        // Remove outer braces and clean up the bundle name
        return bundleName.replace(/[{}]/g, '').trim() || '∅';
    }

    update() {
        if (!this.visible) return;
        
        // Sprites automatically face the camera, so no manual position updates needed
        // But we can adjust scale based on distance for better visibility
        this.labels.forEach((label) => {
            if (label.visible && label.sprite) {
                this.updateLabelScale(label);
            }
        });
    }

    updateLabelScale(label) {
        // Adjust sprite scale based on distance from camera for consistent size
        const distance = this.camera.position.distanceTo(label.position3D);
        const baseDist = 10; // Reference distance
        const scaleFactor = Math.max(0.3, Math.min(2.0, distance / baseDist));
        
        const originalScale = label.sprite.userData.originalScale;
        label.sprite.scale.copy(originalScale).multiplyScalar(scaleFactor);
        
        // Adjust opacity based on distance
        const maxDistance = 50;
        const opacity = Math.max(0.4, Math.min(1.0, 1 - (distance - baseDist) / maxDistance));
        label.sprite.material.opacity = opacity;
    }

    addToScene(scene) {
        // Add the label group to the scene
        scene.add(this.labelGroup);
        
        // Add debug helpers in development
        const isDevelopment = window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1';
        if (isDevelopment) {
            this.labels.forEach(label => {
                const helper = new THREE.SphereGeometry(0.05, 8, 8);
                const material = new THREE.MeshBasicMaterial({ 
                    color: 0xff0000, 
                    transparent: true, 
                    opacity: 0.5 
                });
                const sphere = new THREE.Mesh(helper, material);
                sphere.position.copy(label.position3D);
                sphere.name = `label-helper-${label.index}`;
                scene.add(sphere);
            });
        }
    }

    toggleVisibility(visible) {
        this.visible = visible;
        this.labelGroup.visible = visible;
    }

    showLabel(index, show = true) {
        if (index >= 0 && index < this.labels.length) {
            this.labels[index].visible = show;
            this.labels[index].sprite.visible = show;
        }
    }

    hideLabel(index) {
        this.showLabel(index, false);
    }

    showAllLabels() {
        this.labels.forEach((label, index) => {
            this.showLabel(index, true);
        });
    }

    hideAllLabels() {
        this.labels.forEach((label, index) => {
            this.showLabel(index, false);
        });
    }

    onLabelClick(index, bundleName, position) {
        console.log(`Clicked label ${index}: ${bundleName} at`, position);
        
        // Dispatch custom event for label clicks
        const event = new CustomEvent('labelClick', {
            detail: {
                index: index,
                bundleName: bundleName,
                position: position,
                label: this.labels[index]
            }
        });
        
        window.dispatchEvent(event);
        
        // Show bundle information
        this.showBundleInfo(index, bundleName, position);
    }

    showBundleInfo(index, bundleName, position) {
        // Remove existing info panel
        const existing = document.getElementById('bundle-info');
        if (existing) {
            existing.remove();
        }
        
        // Create info panel
        const infoPanel = document.createElement('div');
        infoPanel.id = 'bundle-info';
        infoPanel.style.cssText = `
            position: fixed;
            top: 20px;
            right: 20px;
            background: rgba(255, 255, 255, 0.95);
            border: 2px solid #333;
            border-radius: 8px;
            padding: 15px;
            font-family: Arial, sans-serif;
            font-size: 14px;
            max-width: 250px;
            z-index: 1000;
            box-shadow: 0 4px 8px rgba(0, 0, 0, 0.2);
        `;
        
        infoPanel.innerHTML = `
            <div style="font-weight: bold; margin-bottom: 10px; color: #333;">
                Bundle Information
            </div>
            <div><strong>Bundle:</strong> ${bundleName}</div>
            <div><strong>Index:</strong> ${index}</div>
            <div><strong>Position:</strong> (${position.x.toFixed(2)}, ${position.y.toFixed(2)}, ${position.z.toFixed(2)})</div>
            <button id="close-bundle-info" style="
                margin-top: 10px;
                padding: 5px 10px;
                background: #f44336;
                color: white;
                border: none;
                border-radius: 4px;
                cursor: pointer;
            ">Close</button>
        `;
        
        document.body.appendChild(infoPanel);
        
        // Add close button handler
        document.getElementById('close-bundle-info').addEventListener('click', () => {
            infoPanel.remove();
        });
        
        // Auto-close after 10 seconds
        setTimeout(() => {
            if (infoPanel.parentNode) {
                infoPanel.remove();
            }
        }, 10000);
    }

    updateLabelContent(index, newContent) {
        if (index >= 0 && index < this.labels.length) {
            this.labels[index].element.textContent = newContent;
        }
    }

    setLabelStyle(index, styles) {
        if (index >= 0 && index < this.labels.length) {
            Object.assign(this.labels[index].element.style, styles);
        }
    }

    // Filter labels based on bundle names
    filterLabels(filterFn) {
        this.labels.forEach((label, index) => {
            const shouldShow = filterFn(label.bundleName, index);
            this.showLabel(index, shouldShow);
        });
    }

    // Get label by bundle name
    getLabelByBundle(bundleName) {
        return this.labels.find(label => label.bundleName === bundleName);
    }

    // Cleanup method
    dispose() {
        // Dispose of all sprite materials and textures
        this.sprites.forEach(sprite => {
            if (sprite.material.map) {
                sprite.material.map.dispose();
            }
            sprite.material.dispose();
        });
        
        // Clear arrays
        this.labels = [];
        this.sprites = [];
        
        // Remove from scene (if added)
        if (this.labelGroup.parent) {
            this.labelGroup.parent.remove(this.labelGroup);
        }
    }
}
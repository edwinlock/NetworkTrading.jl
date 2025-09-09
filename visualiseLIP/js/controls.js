/**
 * LIPControls - Handles user interface controls for LIP visualization
 * Provides transparency, wireframe, view presets, and other interactive controls
 */

export class LIPControls {
    constructor() {
        this.callbacks = {};
        this.controlPanel = null;
    }

    setupUI(callbacks) {
        this.callbacks = callbacks;
        this.createControlPanel();
        this.createControls();
        this.setupEventListeners();
    }

    createControlPanel() {
        this.controlPanel = document.createElement('div');
        this.controlPanel.id = 'control-panel';
        this.controlPanel.style.cssText = `
            position: fixed;
            top: 20px;
            left: 20px;
            background: rgba(255, 255, 255, 0.9);
            border: 1px solid #ccc;
            border-radius: 8px;
            padding: 15px;
            font-family: Arial, sans-serif;
            font-size: 14px;
            min-width: 200px;
            z-index: 1000;
            box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1);
        `;
        
        document.body.appendChild(this.controlPanel);
    }

    createControls() {
        this.controlPanel.innerHTML = `
            <div class="control-header">
                <h3 style="margin: 0 0 15px 0; color: #333; font-size: 16px;">LIP Controls</h3>
            </div>
            
            <div class="control-group">
                <label for="transparency-slider">Transparency: <span id="transparency-value">0.7</span></label>
                <input type="range" id="transparency-slider" min="0.1" max="1.0" step="0.1" value="0.7" 
                       style="width: 100%; margin: 5px 0;">
            </div>
            
            <div class="control-group">
                <label style="margin-bottom: 10px; display: block;">Display Options:</label>
                <div style="margin: 5px 0;">
                    <input type="checkbox" id="wireframe-toggle">
                    <label for="wireframe-toggle">Wireframe Mode</label>
                </div>
                <div style="margin: 5px 0;">
                    <input type="checkbox" id="labels-toggle" checked>
                    <label for="labels-toggle">Show Labels</label>
                </div>
                <div style="margin: 5px 0;">
                    <input type="checkbox" id="axes-toggle" checked>
                    <label for="axes-toggle">Show Axes</label>
                </div>
            </div>
            
            <div class="control-group">
                <label style="margin-bottom: 10px; display: block;">View Presets:</label>
                <div class="view-buttons">
                    <button class="view-btn" data-view="isometric">Isometric</button>
                    <button class="view-btn" data-view="front">Front</button>
                    <button class="view-btn" data-view="back">Back</button>
                    <button class="view-btn" data-view="left">Left</button>
                    <button class="view-btn" data-view="right">Right</button>
                    <button class="view-btn" data-view="top">Top</button>
                    <button class="view-btn" data-view="bottom">Bottom</button>
                </div>
            </div>
            
            <div class="control-group">
                <label style="margin-bottom: 10px; display: block;">Animation:</label>
                <button id="auto-rotate-btn" class="control-button">Auto Rotate</button>
                <button id="reset-view-btn" class="control-button">Reset View</button>
            </div>
            
            <div class="control-group">
                <button id="fullscreen-btn" class="control-button">Toggle Fullscreen</button>
                <button id="export-btn" class="control-button">Export Image</button>
            </div>
            
            <div class="control-group">
                <button id="toggle-panel" class="control-button">Hide Panel</button>
            </div>
        `;
        
        // Add CSS for buttons
        const style = document.createElement('style');
        style.textContent = `
            .view-btn {
                margin: 2px;
                padding: 6px 10px;
                background: #007bff;
                color: white;
                border: none;
                border-radius: 4px;
                cursor: pointer;
                font-size: 12px;
                transition: background-color 0.2s;
            }
            .view-btn:hover {
                background: #0056b3;
            }
            .view-btn:active {
                background: #004085;
            }
            .control-button {
                width: 100%;
                margin: 3px 0;
                padding: 8px;
                background: #28a745;
                color: white;
                border: none;
                border-radius: 4px;
                cursor: pointer;
                font-size: 12px;
                transition: background-color 0.2s;
            }
            .control-button:hover {
                background: #218838;
            }
            .control-button:active {
                background: #1e7e34;
            }
            .control-group {
                margin-bottom: 15px;
                padding-bottom: 10px;
                border-bottom: 1px solid #eee;
            }
            .control-group:last-child {
                border-bottom: none;
                margin-bottom: 0;
            }
            .view-buttons {
                display: grid;
                grid-template-columns: 1fr 1fr;
                gap: 4px;
            }
        `;
        document.head.appendChild(style);
    }

    setupEventListeners() {
        // Transparency slider
        const transparencySlider = document.getElementById('transparency-slider');
        const transparencyValue = document.getElementById('transparency-value');
        
        transparencySlider.addEventListener('input', (event) => {
            const value = parseFloat(event.target.value);
            transparencyValue.textContent = value.toFixed(1);
            if (this.callbacks.onTransparencyChange) {
                this.callbacks.onTransparencyChange(value);
            }
        });

        // Wireframe toggle
        const wireframeToggle = document.getElementById('wireframe-toggle');
        wireframeToggle.addEventListener('change', (event) => {
            if (this.callbacks.onToggleWireframe) {
                this.callbacks.onToggleWireframe(event.target.checked);
            }
        });

        // Labels toggle
        const labelsToggle = document.getElementById('labels-toggle');
        labelsToggle.addEventListener('change', (event) => {
            if (this.callbacks.onToggleLabels) {
                this.callbacks.onToggleLabels(event.target.checked);
            }
        });

        // Axes toggle
        const axesToggle = document.getElementById('axes-toggle');
        axesToggle.addEventListener('change', (event) => {
            if (this.callbacks.onToggleAxes) {
                this.callbacks.onToggleAxes(event.target.checked);
            }
        });

        // View preset buttons
        const viewButtons = document.querySelectorAll('.view-btn');
        viewButtons.forEach(button => {
            button.addEventListener('click', (event) => {
                const view = event.target.getAttribute('data-view');
                if (this.callbacks.onViewPreset) {
                    this.callbacks.onViewPreset(view);
                }
                
                // Visual feedback
                viewButtons.forEach(btn => btn.style.background = '#007bff');
                event.target.style.background = '#ffc107';
                setTimeout(() => {
                    event.target.style.background = '#007bff';
                }, 300);
            });
        });

        // Auto rotate button
        const autoRotateBtn = document.getElementById('auto-rotate-btn');
        let autoRotating = false;
        
        autoRotateBtn.addEventListener('click', () => {
            autoRotating = !autoRotating;
            autoRotateBtn.textContent = autoRotating ? 'Stop Rotation' : 'Auto Rotate';
            autoRotateBtn.style.background = autoRotating ? '#dc3545' : '#28a745';
            
            if (this.callbacks.onAutoRotate) {
                this.callbacks.onAutoRotate(autoRotating);
            }
        });

        // Reset view button
        const resetViewBtn = document.getElementById('reset-view-btn');
        resetViewBtn.addEventListener('click', () => {
            if (this.callbacks.onResetView) {
                this.callbacks.onResetView();
            }
        });

        // Fullscreen button
        const fullscreenBtn = document.getElementById('fullscreen-btn');
        fullscreenBtn.addEventListener('click', () => {
            this.toggleFullscreen();
        });

        // Export button
        const exportBtn = document.getElementById('export-btn');
        exportBtn.addEventListener('click', () => {
            if (this.callbacks.onExportImage) {
                this.callbacks.onExportImage();
            }
        });

        // Toggle panel button
        const togglePanelBtn = document.getElementById('toggle-panel');
        let panelVisible = true;
        
        togglePanelBtn.addEventListener('click', () => {
            panelVisible = !panelVisible;
            const panel = this.controlPanel;
            
            if (panelVisible) {
                panel.style.transform = 'translateX(0)';
                togglePanelBtn.textContent = 'Hide Panel';
            } else {
                const panelWidth = panel.offsetWidth;
                panel.style.transform = `translateX(-${panelWidth - 30}px)`;
                togglePanelBtn.textContent = 'Show Panel';
            }
            
            panel.style.transition = 'transform 0.3s ease';
        });

        // Keyboard shortcuts
        document.addEventListener('keydown', (event) => {
            this.handleKeyboardShortcuts(event);
        });

        // Mouse interaction info
        this.showMouseInstructions();
    }

    handleKeyboardShortcuts(event) {
        switch (event.key.toLowerCase()) {
            case 'w':
                if (event.ctrlKey || event.metaKey) return; // Don't interfere with browser shortcuts
                document.getElementById('wireframe-toggle').click();
                break;
            case 'l':
                if (event.ctrlKey || event.metaKey) return;
                document.getElementById('labels-toggle').click();
                break;
            case 'r':
                if (event.ctrlKey || event.metaKey) return;
                document.getElementById('reset-view-btn').click();
                break;
            case 'f':
                if (event.ctrlKey || event.metaKey) return;
                this.toggleFullscreen();
                break;
            case ' ':
                event.preventDefault();
                document.getElementById('auto-rotate-btn').click();
                break;
            case 'h':
                if (event.ctrlKey || event.metaKey) return;
                document.getElementById('toggle-panel').click();
                break;
        }
    }

    showMouseInstructions() {
        const instructions = document.createElement('div');
        instructions.id = 'mouse-instructions';
        instructions.style.cssText = `
            position: fixed;
            bottom: 20px;
            left: 20px;
            background: rgba(0, 0, 0, 0.8);
            color: white;
            padding: 10px;
            border-radius: 4px;
            font-family: Arial, sans-serif;
            font-size: 12px;
            z-index: 1000;
            transition: opacity 0.3s ease;
        `;
        
        instructions.innerHTML = `
            <div><strong>Mouse Controls:</strong></div>
            <div>• Left click + drag: Rotate</div>
            <div>• Right click + drag: Pan</div>
            <div>• Scroll wheel: Zoom</div>
            <div style="margin-top: 8px;"><strong>Keyboard Shortcuts:</strong></div>
            <div>• W: Wireframe • L: Labels • R: Reset • F: Fullscreen • Space: Auto-rotate • H: Hide panel</div>
        `;
        
        document.body.appendChild(instructions);
        
        // Auto-hide instructions after 10 seconds
        setTimeout(() => {
            instructions.style.opacity = '0.3';
        }, 10000);
        
        // Show on hover
        instructions.addEventListener('mouseenter', () => {
            instructions.style.opacity = '1';
        });
        
        instructions.addEventListener('mouseleave', () => {
            instructions.style.opacity = '0.3';
        });
    }

    toggleFullscreen() {
        if (!document.fullscreenElement) {
            document.documentElement.requestFullscreen().catch(err => {
                console.error('Error attempting to enable fullscreen:', err);
            });
        } else {
            document.exitFullscreen();
        }
    }

    updateStats(stats) {
        // Add or update a stats display
        let statsElement = document.getElementById('stats-display');
        if (!statsElement) {
            statsElement = document.createElement('div');
            statsElement.id = 'stats-display';
            statsElement.style.cssText = `
                position: fixed;
                bottom: 20px;
                right: 20px;
                background: rgba(0, 0, 0, 0.7);
                color: white;
                padding: 10px;
                border-radius: 4px;
                font-family: 'Courier New', monospace;
                font-size: 11px;
                z-index: 1000;
            `;
            document.body.appendChild(statsElement);
        }
        
        statsElement.innerHTML = `
            <div>FPS: ${stats.fps || 'N/A'}</div>
            <div>Triangles: ${stats.triangles || 'N/A'}</div>
            <div>Draw calls: ${stats.drawCalls || 'N/A'}</div>
        `;
    }

    showLoadingIndicator(show = true) {
        let loader = document.getElementById('loading-indicator');
        
        if (show) {
            if (!loader) {
                loader = document.createElement('div');
                loader.id = 'loading-indicator';
                loader.style.cssText = `
                    position: fixed;
                    top: 50%;
                    left: 50%;
                    transform: translate(-50%, -50%);
                    background: rgba(255, 255, 255, 0.9);
                    padding: 20px;
                    border-radius: 8px;
                    font-family: Arial, sans-serif;
                    font-size: 16px;
                    z-index: 2000;
                    text-align: center;
                `;
                loader.innerHTML = `
                    <div>Loading LIP Visualization...</div>
                    <div style="margin-top: 10px; font-size: 12px; color: #666;">
                        Please wait while we process the polyhedral complex
                    </div>
                `;
                document.body.appendChild(loader);
            }
            loader.style.display = 'block';
        } else {
            if (loader) {
                loader.style.display = 'none';
            }
        }
    }

    dispose() {
        if (this.controlPanel && this.controlPanel.parentNode) {
            this.controlPanel.parentNode.removeChild(this.controlPanel);
        }
        
        // Clean up other elements
        const elements = [
            'mouse-instructions',
            'stats-display',
            'loading-indicator'
        ];
        
        elements.forEach(id => {
            const element = document.getElementById(id);
            if (element && element.parentNode) {
                element.parentNode.removeChild(element);
            }
        });
    }
}
'use strict';
'require view';
'require fs';
'require ui';
'require uci';
'require poll';

return view.extend({
    load: function() {
        return Promise.all([
            uci.load('usbgadget'),
            L.resolveDefault(fs.exec('/etc/init.d/usb-gadget', ['status']), null),
            L.resolveDefault(fs.list('/sys/class/udc'), [])
        ]);
    },

    render: function(data) {
        var status_result = data[1];
        var udc_devices = data[2];
        
        var enabled = uci.get('usbgadget', 'usb', 'enabled');
        var gadget_name = uci.get('usbgadget', 'usb', 'gadget_name') || 'g1';
        var manufacturer = uci.get('usbgadget', 'usb', 'manufacturer') || 'OpenWrt';
        
        // Obtener funciones habilitadas
        var functions = [];
        ['rndis', 'ecm', 'ncm', 'acm', 'ums'].forEach(function(func) {
            if (uci.get('usbgadget', func, 'enabled') == '1') {
                var desc = uci.get('usbgadget', func, 'description') || func.toUpperCase();
                functions.push(desc);
            }
        });

        // Construir array de filas de la tabla
        var tableRows = [
            E('tr', { 'class': 'tr' }, [
                E('td', { 'class': 'td left', 'width': '33%' }, E('strong', {}, _('Gadget Status'))),
                E('td', { 'class': 'td left', 'id': 'status_value' }, 
                    enabled == '1' ? 
                        E('span', { 'style': 'color:green' }, '● ' + _('Active (Device Mode)')) :
                        E('span', { 'style': 'color:red' }, '● ' + _('Disabled (Host Mode)'))
                )
            ]),
            
            E('tr', { 'class': 'tr' }, [
                E('td', { 'class': 'td left' }, E('strong', {}, _('Gadget Name'))),
                E('td', { 'class': 'td left' }, gadget_name)
            ]),
            
            E('tr', { 'class': 'tr' }, [
                E('td', { 'class': 'td left' }, E('strong', {}, _('Manufacturer'))),
                E('td', { 'class': 'td left' }, manufacturer)
            ]),
            
            E('tr', { 'class': 'tr' }, [
                E('td', { 'class': 'td left' }, E('strong', {}, _('Enabled Functions'))),
                E('td', { 'class': 'td left' }, 
                    functions.length > 0 ? functions.join(', ') : E('em', {}, _('None')))
            ])
        ];

        // Añadir fila UDC solo si hay dispositivos
        if (udc_devices.length > 0) {
            tableRows.splice(3, 0, E('tr', { 'class': 'tr' }, [
                E('td', { 'class': 'td left' }, E('strong', {}, _('USB Controller'))),
                E('td', { 'class': 'td left' }, udc_devices.map(function(d) { return d.name; }).join(', '))
            ]));
        }

        var viewElements = [
            E('h2', {}, _('USB Gadget Status')),
            E('div', { 'class': 'cbi-map-descr' }, 
                _('View current USB gadget configuration and status')),
            
            E('div', { 'class': 'cbi-section' }, [
                E('h3', {}, _('Current Status')),
                E('table', { 'class': 'table' }, tableRows)
            ]),
            
            E('div', { 'class': 'cbi-section' }, [
                E('div', { 'class': 'cbi-section-node' }, [
                    E('div', { 'class': 'cbi-value' }, [
                        E('label', { 'class': 'cbi-value-title' }, _('Service Control')),
                        E('div', { 'class': 'cbi-value-field' }, [
                            E('button', {
                                'class': 'cbi-button cbi-button-apply',
                                'click': function() {
                                    ui.showModal(_('Restarting service...'), [
                                        E('p', { 'class': 'spinning' }, _('Please wait...'))
                                    ]);
                                    
                                    fs.exec('/etc/init.d/usb-gadget', ['restart'])
                                        .then(function() {
                                            ui.hideModal();
                                            ui.addNotification(null, 
                                                E('p', _('USB Gadget service restarted successfully')), 
                                                'info');
                                        })
                                        .catch(function(e) {
                                            ui.hideModal();
                                            ui.addNotification(null, 
                                                E('p', _('Failed to restart: %s').format(e.message)), 
                                                'error');
                                        });
                                }
                            }, _('Restart Service'))
                        ])
                    ])
                ])
            ])
        ];

        // Añadir output detallado solo si existe
        if (status_result && status_result.stdout) {
            viewElements.push(
                E('div', { 'class': 'cbi-section' }, [
                    E('h3', {}, _('Detailed Output')),
                    E('pre', { 
                        'style': 'background:#f9f9f9; padding:10px; overflow:auto; max-height:400px; border:1px solid #ddd'
                    }, status_result.stdout)
                ])
            );
        }

        var view = E('div', { 'class': 'cbi-map' }, viewElements);

        // Polling cada 5 segundos
        poll.add(function() {
            return uci.load('usbgadget').then(function() {
                var newEnabled = uci.get('usbgadget', 'usb', 'enabled');
                var statusEl = document.getElementById('status_value');
                if (statusEl) {
                    statusEl.innerHTML = '';
                    statusEl.appendChild(
                        newEnabled == '1' ?
                            E('span', { 'style': 'color:green' }, '● ' + _('Active (Device Mode)')) :
                            E('span', { 'style': 'color:red' }, '● ' + _('Disabled (Host Mode)'))
                    );
                }
            });
        }, 5);

        return view;
    },

    handleSaveApply: null,
    handleSave: null,
    handleReset: null
});

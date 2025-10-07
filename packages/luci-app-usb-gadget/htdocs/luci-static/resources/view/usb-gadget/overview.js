'use strict';
'require view';
'require form';
'require fs';
'require ui';
'require uci';
'require rpc';
'require poll';

var callServiceList = rpc.declare({
    object: 'service',
    method: 'list',
    params: ['name'],
    expect: { '': {} }
});

return view.extend({
    load: function() {
        return Promise.all([
            uci.load('usbgadget'),
            L.resolveDefault(fs.exec('/etc/init.d/usb-gadget', ['status']), null),
            L.resolveDefault(fs.list('/sys/class/udc'), []),
            L.resolveDefault(callServiceList('usb-gadget'), {})
        ]);
    },

    render: function(data) {
        var status_result = data[1];
        var udc_devices = data[2];
        
        var enabled = uci.get('usbgadget', 'usb', 'enabled') == '1';
        var gadget_name = uci.get('usbgadget', 'usb', 'gadget_name') || 'g1';
        
        var m, s, o;

        // Crear un mapa simple para mostrar información
        m = new form.JSONMap({}, 
            _('USB Gadget Status'),
            _('View current USB gadget configuration and status'));

        s = m.section(form.NamedSection, '_status', 'status');

        // Status Overview
        o = s.option(form.DummyValue, '_status', _('Gadget Status'));
        o.rawhtml = true;
        o.cfgvalue = function() {
            return enabled ? 
                '<span style="color:green">&#9679;</span> ' + _('Active (Device Mode)') :
                '<span style="color:red">&#9679;</span> ' + _('Disabled (Host Mode)');
        };

        o = s.option(form.DummyValue, '_gadget_name', _('Gadget Name'));
        o.cfgvalue = function() { return gadget_name; };

        // UDC Controller
        if (udc_devices.length > 0) {
            o = s.option(form.DummyValue, '_udc', _('USB Device Controller'));
            o.cfgvalue = function() {
                return udc_devices.map(function(dev) {
                    return dev.name;
                }).join(', ');
            };
        }

        // Enabled Functions
        o = s.option(form.DummyValue, '_functions', _('Enabled Functions'));
        o.cfgvalue = function() {
            var functions = [];
            ['rndis', 'ecm', 'ncm', 'acm', 'ums'].forEach(function(func) {
                if (uci.get('usbgadget', func, 'enabled') == '1') {
                    var desc = uci.get('usbgadget', func, 'description') || func.toUpperCase();
                    functions.push(desc);
                }
            });
            return functions.length > 0 ? functions.join(', ') : _('None');
        };

        // Service Controls
        o = s.option(form.Button, '_restart', _('Service Control'));
        o.inputtitle = _('Restart Service');
        o.inputstyle = 'apply';
        o.onclick = function() {
            return fs.exec('/etc/init.d/usb-gadget', ['restart'])
                .then(function() {
                    ui.addNotification(null, 
                        E('p', _('USB Gadget service restarted')), 
                        'info');
                })
                .catch(function(e) {
                    ui.addNotification(null, 
                        E('p', _('Failed to restart service: %s').format(e.message)), 
                        'error');
                });
        };

        // Detailed Status Output
        if (status_result && status_result.stdout) {
            s = m.section(form.NamedSection, '_details', 'details', 
                _('Detailed Status'));
            
            o = s.option(form.DummyValue, '_output', _('Status Output'));
            o.rawhtml = true;
            o.cfgvalue = function() {
                return '<pre style="background:#f0f0f0; padding:10px; overflow:auto; max-height:400px">' + 
                       status_result.stdout + '</pre>';
            };
        }

        return m.render().then(function(mapNode) {
            poll.add(function() {
                return Promise.all([
                    uci.load('usbgadget'),
                    L.resolveDefault(fs.exec('/etc/init.d/usb-gadget', ['status']), null)
                ]).then(function(pollData) {
                    var newStatus = pollData[1];
                    var statusNode = mapNode.querySelector('[data-name="_status"] .td.right');
                    if (statusNode) {
                        var nowEnabled = uci.get('usbgadget', 'usb', 'enabled') == '1';
                        statusNode.innerHTML = nowEnabled ? 
                            '<span style="color:green">&#9679;</span> ' + _('Active (Device Mode)') :
                            '<span style="color:red">&#9679;</span> ' + _('Disabled (Host Mode)');
                    }
                });
            }, 5);
            
            return mapNode;
        });
    },

    handleSaveApply: null,
    handleSave: null,
    handleReset: null
});

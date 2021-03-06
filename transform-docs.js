#!/usr/bin/env node

// Messy code to post-process html content generated by dox.
// A lot of quick & dirty stuff here

const cheerio = require('cheerio');
const glob = require('glob');
const fs = require('fs');
const { trace } = require('console');

var files = glob.sync(__dirname + '/docs/**/*.html');

for (file of files) {

    var html = fs.readFileSync(file, 'utf8');

    // var index = html.indexOf('</style>');
    // if (index != -1) {
    //     html = html.substring(0, index) + '}' + html.substring(index);
    // }

    var dom = cheerio.load(html);

    var eventFields = [];
    var hasInheritedEventFields = false;
    var inheritedEventFields = {};

    dom('.sidebar-nav > .dropdown').remove();

    dom('.inherited-fields span.identifier').each(function(i, el) {
        var text = dom(el).text().trim();
        if (text.startsWith('_dox_event_')) {
            var field = dom(el).parent().parent().parent().parent();
            var inheritedFromDom = cheerio.load(dom(cheerio.load(field.parent().parent().before().html())('h4')[0]).html());
            var inheritedFrom = dom(inheritedFromDom('.type')[0]);
            var inheritedFromType = inheritedFrom.attr('title').trim();
            hasInheritedEventFields = true;
            if (inheritedEventFields[inheritedFromType] == null) {
                inheritedEventFields[inheritedFromType] = {
                    dom: inheritedFromDom,
                    fields: []
                };
            }
            inheritedEventFields[inheritedFromType].fields.push(field);
            field.remove();
        }
    });

    dom('span.identifier').each(function(i, el) {
        var text = dom(el).text().trim();
        if (text.startsWith('_dox_event_')) {
            var field = dom(el).parent().parent().parent().parent();
            field.remove();
            eventFields.push(field);
        }
    });

    if (hasInheritedEventFields) {

        var eventsDom = cheerio.load('<div class="fields"></div>');

        for (key in inheritedEventFields) {
            var inheritedFromDom = inheritedEventFields[key].dom;
            var fields = inheritedEventFields[key].fields;

            eventsDom('.fields').append('<h4>' + inheritedFromDom.html() + '</h4>');
            eventsDom('.fields').append('<div class="filling-fields" style="display:none"></div>');

            for (eventField of fields) {
                eventsDom('.fields .filling-fields').append(eventField);
            }
            eventsDom('.fields .filling-fields').removeClass('filling-fields');
        }

        dom('.inherited-fields').prepend(eventsDom.html().split('_dox_event_').join(''));
        dom('.inherited-fields').prepend('<h3 class="section">Inherited Events</h3>');

    }

    if (eventFields.length > 0) {

        var eventsDom = cheerio.load('<div class="fields"></div>');

        for (eventField of eventFields) {
            eventsDom('.fields').append(eventField);
        }

        dom('.doc.doc-main').after(eventsDom.html().split('_dox_event_').join(''));
        dom('.doc.doc-main').after('<h3 class="section">Events</h3>');
    }

    dom('p.availability em').each(function(i, el) {
        var text = dom(el).text().trim();
        if (text.indexOf('all platforms') != -1) {
            dom(el).text('Available on all targets');
        }
        else {
            var prefix = 'Available on ';
            if (text.startsWith(prefix)) {
                var hasPlugin = false;
                var isClayWeb = false;
                var isClayNative = false;
                var items = text.substring(prefix.length).split(',');
                for (i = 0; i < items.length; i++) {
                    var item = items[i].trim();
                    if (item.endsWith('-plugin')) {
                        hasPlugin = true;
                    }
                    if (item == 'clay-web') {
                        isClayWeb = true;
                    }
                    if (item == 'clay-native') {
                        isClayNative = true;
                    }
                    items[i] = item.split('-').join(' ');
                }
                if (isClayWeb) {
                    var filtered = [];
                    for (item of items) {
                        if (!item.endsWith(' plugin')) {
                            if (item.startsWith('clay ')) {
                                if (item == 'clay web') {
                                    if (isClayNative) {
                                        filtered.push('clay');
                                    }
                                    else {
                                        filtered.push('clay web');
                                    }
                                }
                            }
                        }
                    }
                    dom(el).text(prefix + filtered.join(', '));
                }
                else if (hasPlugin) {
                    if (items.length == 2 && items.indexOf('elements plugin') != -1 && items.indexOf('ui plugin') != -1) {
                        items = ['ui plugin'];
                    }
                    dom(el).text('Available with ' + items.join(', '));
                }
                else {
                    dom(el).text(prefix + items.join(', '));
                }
            }
        }
    });

    dom('.section-availability').each(function(i, el) {
        var text = dom(el).text().trim();
        var items = text.split(',');
        var isClayWeb = false;
        var isClayNative = false;
        for (i = 0; i < items.length; i++) {
            var item = items[i].trim();
            if (item == 'clay-web') {
                isClayWeb = true;
            }
            if (item == 'clay-native') {
                isClayNative = true;
            }
            items[i] = item.split('-').join(' ');
        }
        if (isClayWeb) {
            var filtered = [];
            for (item of items) {
                if (!item.endsWith(' plugin')) {
                    if (item.startsWith('clay ')) {
                        if (item == 'clay web') {
                            if (isClayNative) {
                                filtered.push('clay');
                            }
                            else {
                                filtered.push('clay web');
                            }
                        }
                    }
                }
            }
            dom(el).text(filtered.join(', '));
        }
        else {
            dom(el).text(items.join(', '));
        }
    });

    console.log('save ' + file);
    html = dom.html();
    fs.writeFileSync(file, html);

}

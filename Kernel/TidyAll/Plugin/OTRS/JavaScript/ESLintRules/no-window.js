/**
 * @fileoverview Rule to disallow usage of window object
 * @author Marc Nilius
 */

"use strict";

//------------------------------------------------------------------------------
// Rule Definition
//------------------------------------------------------------------------------

module.exports = function(context) {

    return {
        "MemberExpression": function(node) {
            if (node.object.type === 'Identifier') {
                var ObjectName = node.object.name,
                    PropertyName,
                    ReservedWords = ["opener", "parent", "open", "name"];

                if (ObjectName === 'window') {
                    if (node.property.type === 'Identifier') {
                        PropertyName = node.property.name;

                        if (ReservedWords.indexOf("" + PropertyName) !== -1) {
                            context.report(node, "Do not use the 'window' object. Use the OTRS functions in Core.UI.Popup instead: window.{{property}}", { property: PropertyName });
                        }
                    }
                }
            }
        }
    };
};

module.exports.schema = [];
import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

Popup {
    id: root

    function constructRegExp() {
        var selectedCount = 0;
        var re = ".*(";
        SharedData.selectedGenres.forEach(function(e, index) {
            if (e) {
                re += SharedData.genres[index] + "|";
                selectedCount++;
            }
        });

        if (selectedCount === 0) {
            SharedData.pattern = "";
            return;
        }

        re = re.substring(0, re.length - 1);
        re += ")";

        if (selectedCount > 1) {
            var firstGroup = re;
            for (var i = 1; i < selectedCount; i++)
                re += firstGroup;
        }
        re += ".*";

        SharedData.pattern = re;
    }

    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    GridLayout {
        columns: 4

        Repeater {
            model: SharedData.genres
            delegate: Button {
                flat: true
                checkable: true
                text: modelData
                checked: true === SharedData.selectedGenres[index]

                Layout.fillWidth: true

                onClicked: {
                    SharedData.selectedGenres[index] = checked;
                    constructRegExp();
                }
            }
        }
    }
}

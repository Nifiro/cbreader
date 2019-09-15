import QtQuick 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls 2.12
import QtQuick.Controls.Material 2.12

import NetworkManager 1.0

Popup {
    id: root

    property string apiKey: "trnsl.1.1.20190608T110416Z.37b091ea44a49087.2a695e83206b0d34c309f7f319d66461c36e1f94"

    ColumnLayout {
        anchors.fill: parent

        CustomTextField {
            id: sourceText
            placeholderText: qsTr("Translate...")
            Layout.fillWidth: true

            onAccepted: {
                if (text && NetworkManager.online) {
                    var xhr = new XMLHttpRequest();
                    xhr.onreadystatechange = function() {
                        if (xhr.readyState === XMLHttpRequest.DONE) {
                            if (xhr.status === 200)
                            {
                                var response = JSON.parse(xhr.responseText);
                                translationText.text = response.text.toString();
                            }
                        }
                    }
                    xhr.open("GET", "https://translate.yandex.net/api/v1.5/tr.json/translate" +
                                 "?key=" + root.apiKey +
                                 "&text=" + encodeURI(sourceText.text) +
                                 "&lang=en-ru&format=plain");
                    xhr.send();
                }
                focus = false;
            }
        }
        Flickable {
            id: flickable
            boundsBehavior: Flickable.StopAtBounds
            flickableDirection: Flickable.VerticalFlick

            Layout.fillWidth: true
            Layout.fillHeight: true

            TextArea.flickable: TextArea {
                id: translationText
                background: Rectangle {
                    color: "transparent"
                    border {
                        width: 2
                        color: root.Material.rippleColor
                    }
                }
                clip: true
                readOnly: true
                padding: 12
                wrapMode: TextEdit.Wrap
            }

            ScrollIndicator.vertical: ScrollIndicator {}
        }
    }
}

#include <QCoreApplication>
#include <QDir>
#include <QQmlComponent>
#include <QQmlEngine>

int main(int argc, char **argv)
{
    QCoreApplication application(argc, argv);
    QQmlEngine engine;
    const QString qtImportPath = qEnvironmentVariable("QT_TARGET_QML_PATH");
    if (!qtImportPath.isEmpty()) {
        engine.addImportPath(qtImportPath);
    }
    engine.addImportPath(qEnvironmentVariable(
        "EASTASIAN_IME_QML_IMPORT_PATH",
        QStringLiteral(EASTASIAN_IME_TEST_IMPORT_PATH)));

    QQmlComponent component(&engine);
    component.setData(R"QML(
        import QtQml
        import io.codex.EastAsianIme 1.0
        EastAsianIme {}
    )QML", QUrl());
    QScopedPointer<QObject> object(component.create());
    if (object.isNull()) {
        qCritical() << component.errors();
        return 1;
    }
    return 0;
}

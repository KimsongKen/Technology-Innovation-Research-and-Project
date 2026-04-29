package Demo;

import javax.swing.*;
import java.awt.*;
import java.awt.event.MouseAdapter;
import java.awt.event.MouseEvent;
import java.awt.geom.*;

public class SelectionPanel extends JPanel {

    private SmartAdaptiveClinicalAssistant mainFrame;
    private String selectedPart = null;

    // 6个部位的热区（矩形范围）
    private final Rectangle HEAD_ZONE = new Rectangle(155, 20, 90, 100);
    private final Rectangle CHEST_ZONE = new Rectangle(155, 125, 90, 100);
    private final Rectangle STOMACH_ZONE = new Rectangle(155, 230, 90, 80);
    private final Rectangle LEFT_ARM_ZONE = new Rectangle(60, 130, 80, 200);
    private final Rectangle RIGHT_ARM_ZONE = new Rectangle(260, 130, 80, 200);
    private final Rectangle LEGS_ZONE = new Rectangle(140, 320, 120, 200);

    public SelectionPanel(SmartAdaptiveClinicalAssistant frame) {
        this.mainFrame = frame;
        setBackground(Color.WHITE);
        setLayout(new BorderLayout(10, 10));
        setBorder(BorderFactory.createEmptyBorder(20, 20, 20, 20));

        // 顶部
        JPanel topPanel = new JPanel(new BorderLayout());
        topPanel.setBackground(Color.WHITE);

        JButton backBtn = new JButton("← Back");
        backBtn.setFont(new Font("Arial", Font.PLAIN, 14));
        backBtn.addActionListener(e -> mainFrame.showHome());
        topPanel.add(backBtn, BorderLayout.WEST);

        JLabel title = new JLabel("Point to where it hurts", SwingConstants.CENTER);
        title.setFont(new Font("Arial", Font.BOLD, 22));
        topPanel.add(title, BorderLayout.CENTER);

        add(topPanel, BorderLayout.NORTH);

        // 中间：人体图
        BodyMapPanel bodyPanel = new BodyMapPanel();
        bodyPanel.addMouseListener(new MouseAdapter() {
            @Override
            public void mouseClicked(MouseEvent e) {
                int x = e.getX();
                int y = e.getY();

                if (HEAD_ZONE.contains(x, y)) {
                    selectedPart = "Head";
                } else if (CHEST_ZONE.contains(x, y)) {
                    selectedPart = "Chest";
                } else if (STOMACH_ZONE.contains(x, y)) {
                    selectedPart = "Stomach";
                } else if (LEFT_ARM_ZONE.contains(x, y) || RIGHT_ARM_ZONE.contains(x, y)) {
                    selectedPart = "Arms";
                } else if (LEGS_ZONE.contains(x, y)) {
                    selectedPart = "Legs";
                } else if (y > 125 && y < 310 && x > 140 && x < 260) {
                    selectedPart = "Back";
                } else {
                    return;
                }

                bodyPanel.repaint();

                // 跳转到症状选择页
                mainFrame.getContentPane().removeAll();
                mainFrame.getContentPane().add(new SymptomPanel(mainFrame, selectedPart));
                mainFrame.revalidate();
                mainFrame.repaint();
            }
        });

        add(bodyPanel, BorderLayout.CENTER);

        // 底部提示
        JLabel hint = new JLabel("Click on the body part that hurts", SwingConstants.CENTER);
        hint.setFont(new Font("Arial", Font.ITALIC, 13));
        hint.setForeground(Color.GRAY);
        add(hint, BorderLayout.SOUTH);
    }

    // 人体图绘制
    class BodyMapPanel extends JPanel {
        @Override
        protected void paintComponent(Graphics g) {
            super.paintComponent(g);
            Graphics2D g2 = (Graphics2D) g;
            g2.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);

            // 头
            drawPart(g2, HEAD_ZONE, "Head", "🧠");
            // 胸
            drawPart(g2, CHEST_ZONE, "Chest", "🫁");
            // 肚子
            drawPart(g2, STOMACH_ZONE, "Stomach", "🔵");
            // 左臂
            drawPart(g2, LEFT_ARM_ZONE, "L-Arm", "");
            // 右臂
            drawPart(g2, RIGHT_ARM_ZONE, "R-Arm", "");
            // 腿
            drawPart(g2, LEGS_ZONE, "Legs", "");
            // 背（覆盖在胸腹上，用虚线表示）
            g2.setColor(Color.LIGHT_GRAY);
            g2.setStroke(new BasicStroke(1, BasicStroke.CAP_ROUND, BasicStroke.JOIN_ROUND, 0, new float[]{5}, 0));
            g2.draw(new RoundRectangle2D.Double(150, 130, 100, 175, 20, 20));
            g2.drawString("Back", 180, 220);
            g2.setStroke(new BasicStroke(1));
        }

        private void drawPart(Graphics2D g2, Rectangle rect, String name, String emoji) {
            boolean isSelected = name.equals(selectedPart) ||
                    (name.equals("L-Arm") && "Arms".equals(selectedPart)) ||
                    (name.equals("R-Arm") && "Arms".equals(selectedPart));

            if (isSelected) {
                g2.setColor(new Color(255, 200, 200));
            } else {
                g2.setColor(new Color(200, 220, 240));
            }

            g2.fill(new RoundRectangle2D.Double(rect.x, rect.y, rect.width, rect.height, 15, 15));
            g2.setColor(Color.BLACK);
            g2.draw(new RoundRectangle2D.Double(rect.x, rect.y, rect.width, rect.height, 15, 15));

            // 文字居中
            String displayName = name.equals("L-Arm") || name.equals("R-Arm") ? "Arm" : name;
            FontMetrics fm = g2.getFontMetrics();
            int textX = rect.x + (rect.width - fm.stringWidth(displayName)) / 2;
            int textY = rect.y + rect.height / 2;
            g2.drawString(displayName, textX, textY);
        }
    }
}